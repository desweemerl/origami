defmodule Origami.Translator do
  use GenServer

  require Logger

  @default_source_path "/lib/templates"
  @default_target_path "/static/templates"

  defp build_root_path(file) when is_binary(file), do: Path.join(File.cwd!(), file)

  defp path_to_files(path) do
    cond do
      File.dir?(path) ->
        File.ls!(path)
        |> Enum.map(&Path.join(path, &1))
        |> Enum.flat_map(&path_to_files(&1))

      File.regular?(path) ->
        [path]

      true ->
        raise "Cannot match path"
    end
  end

  defp process_content(content, file) do
    {:ok, nodes} = Floki.parse_document(content)
    nodes |> Enum.reduce(%Origami.Document{}, &Origami.Processor.process_node(file, &1, &2))
  end

  defp translate_file(file, source, target) do
    relative_path = Path.relative_to(file, source)
    root_name = Path.rootname(relative_path)
    content = File.read!(file)
    md5_hash = :crypto.hash(:md5, content) |> Base.encode16(case: :lower)
    target_file = Path.join(target, "#{root_name}.#{md5_hash}.js")

    if !File.regular?(target_file) do
      Logger.debug("translating #{relative_path} to #{target_file} ...")
      process_content(content, target_file)
      {:ok, target_file}
    else
      {:nochange, target_file}
    end
  end

  defp translate_paths(source, target) when is_binary(source),
    do: translate_paths([source], target)

  defp translate_paths(source, target) when is_list(source),
    do: source |> path_to_files |> Enum.each(&translate_file(&1, source, target))

  def init(opts) do
    source_path =
      Keyword.get(opts, :source_path, @default_source_path)
      |> build_root_path

    target_path =
      Keyword.get(opts, :target_path, @default_target_path)
      |> build_root_path

    translate_paths(source_path, target_path)

    watcher_pid =
      if Keyword.get(opts, :watch, true) do
        {:ok, pid} = watch_changes(source_path)
        pid
      else
        nil
      end

    {
      :ok,
      %{
        watcher_pid: watcher_pid,
        source_path: source_path,
        target_path: target_path
      }
    }
  end

  def handle_info({:file_event, _pid, {path, events}}, state) do
    Logger.info("File #{path}} events #{inspect(events)}")
    {:noreply, state}
  end

  def handle_info({:file_event, _pid, :stop}, state) do
    Logger.info("Watch stopped")
    {:noreply, state}
  end

  defp watch_changes(source_path) do
    {:ok, pid} = FileSystem.start_link(dirs: [source_path], name: :translator_watcher)
    FileSystem.subscribe(:translator_watcher)
    {:ok, pid}
  end

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end
end

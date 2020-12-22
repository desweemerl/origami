defmodule Origami.Parser.Buffer do
  @moduledoc false

  alias __MODULE__
  alias Origami.Parser.{Interval, Position}

  @defaultBuffer Origami.Parser.BufferText

  @type buffer :: term()

  @type source :: term()

  @type options :: list()

  @type t() :: {Buffer, buffer}

  @callback init(source, options) :: buffer

  @callback position(buffer) :: Position.t()

  @callback over?(buffer) :: bool

  @callback end_line?(buffer) :: bool

  @callback consume_lines(buffer, pos_integer) :: buffer

  @callback consume_chars(buffer, pos_integer) :: buffer

  @callback get_chars(buffer, pos_integer) :: String.t() | nil

  def from(source, options) do
    {mod, buffer_options} = Keyword.pop(options, :type, @defaultBuffer)
    {mod, mod.init(source, buffer_options)}
  end

  def over?({mod, buffer}), do: mod.over?(buffer)

  def end_line?({mod, buffer}), do: mod.end_line?(buffer)

  def get_char({mod, buffer}), do: mod.get_chars(buffer, 1)

  def get_chars({mod, buffer}, num_chars),
    do: mod.get_chars(buffer, num_chars)

  def consume_char({mod, buffer}), do: {mod, mod.consume_chars(buffer, 1)}

  def consume_chars({mod, buffer}, length) when is_number(length) do
    {mod, mod.consume_chars(buffer, length)}
  end

  def consume_chars(mod_buffer, fun) when is_function(fun) do
    case fun.(get_char(mod_buffer)) do
      true ->
        consume_char(mod_buffer)
        |> consume_chars(fun)

      _ ->
        mod_buffer
    end
  end

  def position({mod, buffer}), do: mod.position(buffer)

  def interval({old_mod, old_buffer}, {new_mod, new_buffer}) do
    start = old_mod.position(old_buffer)
    stop = new_mod.position(new_buffer)

    new_stop =
      cond do
        (lines = stop.line - start.line - 1) >= 0 ->
          buffer =
            cond do
              lines > 0 ->
                new_mod.consume_lines(new_buffer, lines)

              true ->
                old_buffer
            end

          new_stop = new_mod.position(buffer)
          remaining_chars = new_mod.get_chars(buffer, -1)

          Position.new(
            new_stop.line,
            max(0, new_stop.col + String.length(remaining_chars) - 1)
          )

        true ->
          Position.new(
            stop.line,
            max(0, stop.col - 1)
          )
      end

    Interval.new(start, new_stop)
  end

  def consume_line({mod, buffer}), do: {mod, mod.consume_lines(buffer, 1)}

  def consume_lines({mod, buffer}, lines), do: {mod, mod.consume_lines(buffer, lines)}

  def current_line({mod, buffer}), do: {mod, mod.current_line(buffer)}

  def check_chars({mod, buffer}, chars) do
    mod.get_chars(buffer, String.length(chars)) == chars
  end

  def next_char({mod, buffer}), do: next_chars({mod, buffer}, 1)

  def next_chars({mod, buffer}, length) do
    chars = mod.get_chars(buffer, length)

    {chars, {mod, mod.consume_chars(buffer, String.length(chars))}}
  end

  def chars_until(mod_buffer, chars, options \\ []) do
    chars_until(mod_buffer, chars, "", options)
  end

  defp chars_until({mod, buffer} = mod_buffer, chars, content, options) do
    cond do
      Buffer.over?(mod_buffer) ->
        :nomatch

      true ->
        new_content = mod.get_chars(buffer, -1)

        case :binary.match(new_content, chars) do
          :nomatch ->
            case Keyword.get(options, :scope_line, false) do
              false ->
                chars_until(
                  Buffer.consume_line(mod_buffer),
                  chars,
                  content <> new_content,
                  options
                )

              _ ->
                :nomatch
            end

          {position, _} ->
            l = String.length(chars)
            {new_content, new_buffer} = Buffer.next_chars(mod_buffer, position + l)

            case Keyword.get(options, :exclude_chars, false) do
              true ->
                {content <> String.slice(new_content, 0..(String.length(new_content) - l - 1)),
                 new_buffer}

              _ ->
                {content <> new_content, new_buffer}
            end
        end
    end
  end
end

defmodule Origami.Parser.BufferText do
  @moduledoc false

  alias __MODULE__
  alias Origami.Parser.{Buffer, Position}

  @behaviour Buffer

  defstruct [:file, :content, line: 0, col: 0]

  @impl Buffer
  def init(content, options \\ []) do
    %BufferText{
      file: Keyword.get(options, :file, nil),
      content: Regex.split(~r/\r\n|\n|\r/, content),
      line: Keyword.get(options, :line_shift, 0),
      col: 0
    }
  end

  defp remove_lines([], _), do: []

  defp remove_lines(content, 0), do: content

  defp remove_lines([_ | tail], lines), do: remove_lines(tail, lines - 1)

  @impl Buffer
  def position(buffer), do: Position.new(buffer.line, buffer.col)

  @impl Buffer
  def over?(%BufferText{content: []}), do: true

  @impl Buffer
  def over?(%BufferText{}), do: false

  @impl Buffer
  def end_line?(%BufferText{content: []}), do: true

  @impl Buffer
  def end_line?(%BufferText{col: col, content: [chars | _]}), do: String.length(chars) <= col

  @impl Buffer
  def consume_lines(%BufferText{content: []} = buffer, _), do: buffer

  @impl Buffer
  def consume_lines(%BufferText{content: content, line: line} = buffer, -1) do
    %BufferText{buffer | content: [], line: line + length(content), col: 0}
  end

  @impl Buffer
  def consume_lines(%BufferText{content: content, line: line} = buffer, lines) when lines > 0 do
    cond do
      length(content) < lines ->
        consume_lines(buffer, -1)

      true ->
        %BufferText{buffer | content: remove_lines(content, lines), line: line + lines, col: 0}
    end
  end

  @impl Buffer
  def consume_chars(buffer, -1), do: consume_lines(buffer, 1)

  @impl Buffer
  def consume_chars(%BufferText{content: []} = buffer, _), do: buffer

  @impl Buffer
  def consume_chars(%BufferText{col: col, content: [chars | _]} = buffer, num_chars) do
    cond do
      String.length(chars) <= col + num_chars ->
        consume_lines(buffer, 1)

      true ->
        %BufferText{buffer | col: col + num_chars}
    end
  end

  @impl Buffer
  def get_chars(%BufferText{content: []}, _), do: ""

  @impl Buffer
  def get_chars(%BufferText{content: [chars | _], col: col}, -1) do
    String.slice(chars, col..-1)
  end

  @impl Buffer
  def get_chars(
        %BufferText{content: [chars | _], col: col} = buffer,
        num_chars
      ) do
    cond do
      String.length(chars) < col + num_chars ->
        get_chars(buffer, -1)

      true ->
        String.slice(chars, col, num_chars)
    end
  end
end

defmodule Origami.SyntaxError do
  defexception [:message, :file, :line, :column]

  @impl true
  def message(exception) do
    "#{exception.file}:#{exception.line}#{exception.column}: #{exception.message}"
  end
end

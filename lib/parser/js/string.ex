defmodule Origami.Parser.Js.String do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Error, Token}

  @behaviour Parser

  @impl Parser
  def consume(buffer, token) do
    cond do
      (char = Buffer.get_char(buffer)) in ["\"", "'"] ->
        content(Buffer.consume_char(buffer), token, char)

      true ->
        :nomatch
    end
  end

  defp content(buffer, token, delimiter) do
    case IO.inspect(Buffer.chars_until(buffer, delimiter, scope_line: true)) do
      :nomatch ->
        new_buffer = Buffer.consume_lines(buffer, -1)

        new_token =
          Token.new(
            :string,
            start: Buffer.position(buffer),
            stop: Buffer.position(new_buffer),
            error: Error.new("Unmatching #{delimiter}")
          )

        {
          :cont,
          new_buffer,
          Token.concat(token, new_token)
        }

      {content, new_buffer} ->
        new_token =
          Token.new(
            :string,
            start: Buffer.position(buffer),
            stop: Buffer.position(new_buffer),
            content: String.slice(content, 0, String.length(content) - 1)
          )

        {
          :cont,
          new_buffer,
          Token.concat(token, new_token)
        }
    end
  end
end

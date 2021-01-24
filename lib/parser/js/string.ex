defmodule Origami.Parser.Js.String do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Error, Token}

  @behaviour Parser

  @impl Parser
  def consume(buffer, token) do
    {char, new_buffer} = Buffer.get_char(buffer)

    cond do
      char in ["\"", "'"] ->
        content(new_buffer, token, char)

      true ->
        :nomatch
    end
  end

  defp content(buffer, token, delimiter) do
    case Buffer.chars_until(buffer, delimiter, scope_line: true) do
      :nomatch ->
        new_buffer = Buffer.consume_lines(buffer, -1)

        new_token =
          Token.new(
            :string,
            interval: Buffer.interval(buffer, new_buffer),
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
            interval: Buffer.interval(buffer, new_buffer),
            data: %{
              content: String.slice(content, 0, String.length(content) - 1)
            }
          )

        {
          :cont,
          new_buffer,
          Token.concat(token, new_token)
        }
    end
  end
end

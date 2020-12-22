defmodule Origami.Parser.Js.Identifier do
  alias Origami.Parser
  alias Origami.Parser.{Buffer, Token}
  alias Origami.Parser.Js.Keyword

  @behaviour Parser

  defp first_char?(<<c>>), do: c in ?a..?z || c in ?A..?Z || c == ?_ || c == ?$
  defp char?(<<c>>), do: first_char?(<<c>>) || c in ?0..?9

  defp get_identifier(buffer, "") do
    cond do
      (char = Buffer.get_char(buffer)) != "" && first_char?(char) ->
        get_identifier(Buffer.consume_char(buffer), char)

      true ->
        {buffer, ""}
    end
  end

  defp get_identifier(buffer, identifier) do
    cond do
      (char = Buffer.get_char(buffer)) != "" && char?(char) ->
        get_identifier(Buffer.consume_char(buffer), identifier <> char)

      true ->
        {buffer, identifier}
    end
  end

  def get_identifier(buffer), do: get_identifier(buffer, "")

  @impl Parser
  def consume(buffer, token) do
    case get_identifier(buffer) do
      {_, ""} ->
        :nomatch

      {new_buffer, identifier} ->
        cond do
          Keyword.keyword?(identifier) ->
            :nomatch

          identifier == "function" ->
            :nomatch

          true ->
            new_token =
              Token.new(
                :identifier,
                interval: Buffer.interval(buffer, new_buffer),
                name: identifier
              )

            {
              :cont,
              new_buffer,
              Token.concat(token, new_token)
            }
        end
    end
  end
end

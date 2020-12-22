defmodule Origami.Parser.Js.Function do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Token}
  alias Origami.Parser.Js.{Group, Space, Identifier}

  @behaviour Parser

  @impl Parser
  def consume(buffer, token) do
    cond do
      Buffer.check_chars(buffer, "function") ->
        parse_function(buffer, token)

      true ->
        :nomatch
    end
  end

  defp parse_function(buffer, token) do
    {buffer_name, name} =
      buffer
      |> Buffer.consume_chars(8)
      |> Buffer.consume_chars(fn char -> Space.space?(char) end)
      |> Identifier.get_identifier()

    {buffer_arguments, arguments} =
      buffer_name
      |> Buffer.consume_chars(fn char -> Space.space?(char) end)
      |> Group.get_group(:parenthesis)

    {buffer_body, body} =
      buffer_arguments
      |> Buffer.consume_chars(fn char -> Space.space?(char) end)
      |> Group.get_group(:brace)

    new_token =
      Token.new(
        :function,
        interval: Buffer.interval(buffer, buffer_body),
        name: name,
        arguments: arguments.children,
        children: body.children
      )

    {
      :cont,
      buffer_body,
      Token.concat(token, new_token)
    }
  end
end

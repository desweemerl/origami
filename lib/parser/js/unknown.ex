defmodule Origami.Parser.Js.Unknown do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Token}

  @behaviour Parser

  defp merge(token, child_token) do
    case token |> Token.get(:children, []) |> Enum.reverse() do
      [%Token{type: :unknown, data: %{content: content}} = head | tail] ->
        new_content = content <> child_token.data.content
        new_head = Token.put(head, :content, new_content)
        Token.put(token, :children, Enum.reverse([new_head | tail]))

      _ ->
        Token.concat(token, child_token)
    end
  end

  @impl Parser
  def consume(buffer, token) do
    {char, new_buffer} = Buffer.get_char(buffer)

    new_token =
      Token.new(
        :unknown,
        Buffer.interval(buffer, new_buffer),
        content: char
      )

    {
      :cont,
      new_buffer,
      merge(token, new_token)
    }
  end
end

defmodule Origami.Parser.Js.Expression do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Interval, Token}

  @behaviour Parser

  defp recursive_lookup(token) do
    case token do
      %Token{type: :group, children: children, data: %{category: :parenthesis}} = group_token ->
        %Token{group_token | children: generate_expression(children)}

      _ ->
        token
    end
  end

  defp generate_expression(tokens) do
    case tokens do
      [
        left_token,
        %Token{type: :operator, data: %{category: category, content: content}},
        right_token | remaining_tokens
      ]
      when category in [:arithmetic] ->
        new_token =
          Token.new(
            :expression,
            interval: Interval.merge(left_token.interval, right_token.interval),
            data: %{
              left: left_token |> recursive_lookup,
              right: right_token |> recursive_lookup,
              operator: content
            }
          )

        generate_expression([new_token | remaining_tokens])

      _ ->
        tokens
    end
  end

  @impl Parser
  def rearrange(tokens), do: generate_expression(tokens)
end

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

  defp get_expression_token(tokens) do
    case tokens do
      [%Token{type: :expression} = head | tail] ->
        {head, tail}

      _ ->
        {nil, tokens}
    end
  end

  defp generate_expression(tokens) do
    case tokens do
      [
        %Token{type: :identifier} = identifier_token,
        %Token{type: :operator, data: %{category: :assignment, content: content}}
        | remaining_tokens
      ] ->
        {right_token, next_tokens} =
          remaining_tokens |> generate_expression |> get_expression_token

        right_interval =
          case right_token do
            nil ->
              identifier_token

            _ ->
              right_token.interval
          end

        new_token =
          Token.new(
            :expression,
            interval: Interval.merge(identifier_token.interval, right_interval),
            data: %{
              left: identifier_token,
              right: right_token,
              operator: content,
              category: :assignment
            }
          )

        [new_token | next_tokens]

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
              operator: content,
              category: category
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

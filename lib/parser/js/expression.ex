defmodule Origami.Parser.Js.Expression do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Interval, Js, Token}

  @behaviour Parser

  defp get_expression_token(tokens) do
    case tokens do
      [head | tail] ->
        {head, tail}

      _ ->
        {nil, tokens}
    end
  end

  def generate_expression(tokens) do
    case tokens do
      [
        %Token{type: type} = identifier_token,
        %Token{type: :operator, data: %{category: :assignment, content: content}} = operator_token
        | remaining_tokens
      ]
      when type in [:store_variable, :identifier] ->
        {right_token, next_tokens} =
          remaining_tokens |> generate_expression |> get_expression_token

        right_interval =
          case right_token do
            nil ->
              operator_token.interval

            _ ->
              right_token.interval
          end

        new_token =
          Token.new(
            :expression,
            interval: Interval.merge(identifier_token.interval, right_interval),
            data: %{
              left: identifier_token,
              right: Js.rearrange_token(right_token),
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
              left: Js.rearrange_token(left_token),
              right: Js.rearrange_token(right_token),
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

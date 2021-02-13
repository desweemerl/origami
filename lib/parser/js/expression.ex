defmodule Origami.Parser.Js.Expression do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Error, Interval, Js, Token}

  @behaviour Parser

  @allowed_argument_types ~w(expression number identifier group)a
  @allowed_side_types ~w(expression number identifier group)a

  defp get_expression_token(tokens) do
    case tokens do
      [head | tail] ->
        {head, tail}

      _ ->
        {nil, tokens}
    end
  end

  defp parse_arguments(tokens, arguments \\ []) do
    case tokens do
      [] ->
        arguments

      [%Token{type: type} = argument | tail]
      when type in @allowed_argument_types ->
        case tail do
          [] ->
            arguments ++ [argument]

          [%Token{type: :punctuation, data: %{category: :comma}} | next_tokens] ->
            parse_arguments(next_tokens, arguments ++ [argument])

          [head | _] ->
            {:error, Error.new("unexpected token", interval: head.interval)}
        end

      [head | _] ->
        {:error, Error.new("unexpected token", interval: head.interval)}
    end
  end

  defp check_side_token(%Token{type: type} = token)
       when type in @allowed_side_types do
    token
  end

  defp check_side_token(token) do
    Token.put(token, :error, Error.new("unexpected token"))
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
          remaining_tokens |> generate_expression() |> get_expression_token()

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
            Interval.merge(identifier_token.interval, right_interval),
            left: identifier_token,
            right: Js.rearrange_token(right_token) |> check_side_token(),
            operator: content,
            category: :assignment
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
            Interval.merge(left_token.interval, right_token.interval),
            left: Js.rearrange_token(left_token) |> check_side_token(),
            right: Js.rearrange_token(right_token) |> check_side_token(),
            operator: content,
            category: category
          )

        generate_expression([new_token | remaining_tokens])

      [
        %Token{type: :identifier} = identifier_token,
        %Token{type: :group, data: %{category: :parenthesis}} = arguments_token
        | remaining_tokens
      ] ->
        arguments =
          Token.get(arguments_token, :children, [])
          |> Js.rearrange_tokens()
          |> parse_arguments()

        new_token =
          Token.new(
            :expression,
            Interval.merge(identifier_token.interval, arguments_token.interval),
            callee: identifier_token,
            arguments: arguments,
            category: :call
          )

        [new_token | remaining_tokens]

      _ ->
        tokens
    end
  end

  @impl Parser
  def rearrange(tokens), do: generate_expression(tokens)

  @impl Parser
  def check(%Token{type: :expression} = token) do
    Token.get(token, :left)
    |> Js.check_token()
    |> Enum.concat(Token.get(token, :right) |> Js.check_token())
    |> Enum.concat(Token.get(token, :arguments, []) |> Js.check_tokens())
  end

  @impl Parser
  def check(_), do: []
end

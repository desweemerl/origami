defmodule Origami.Parser.Js.Expression do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Error, Interval, Js, Token}

  @behaviour Parser

  defguardp is_operand_type(type) when type in [:number, :identifier, :expression]

  defp get_expression_token(tokens) do
    case tokens do
      [head | tail] ->
        {head, tail}

      _ ->
        {nil, tokens}
    end
  end

  defp process_arguments(tokens, arguments \\ []) do
    case tokens do
      [] ->
        arguments

      [%Token{type: type} = argument | tail] when is_operand_type(type) ->
        case tail do
          [] ->
            arguments ++ [argument]

          [%Token{type: :punctuation, data: %{category: :comma}} | next_tokens] ->
            process_arguments(next_tokens, arguments ++ [argument])

          [head | _] ->
            {:error, Error.new("unexpected token", interval: head.interval)}
        end

      [head | _] ->
        {:error, Error.new("unexpected token", interval: head.interval)}
    end
  end

  defp process_sub_token(%Token{type: type} = token) when is_operand_type(type) do
    token
  end

  defp process_sub_token(
         %Token{
           type: :group,
           interval: interval,
           data: %{children: children}
         } = token
       ) do
    case generate_expression(children) do
      [%Token{type: type} = child_token] when is_operand_type(type) ->
        Token.put(child_token, :interval, interval)

      [unknown_token | _] ->
        Token.put(
          token,
          :error,
          Error.new("unexpected token", interval: unknown_token.interval)
        )

      _ ->
        Token.put(
          token,
          :error,
          Error.new("unexpected token", interval: token.interval)
        )
    end
  end

  defp process_sub_token(token) do
    Token.put(token, :error, Error.new("unexpected token"))
  end

  # Manage assignment a = value
  def generate_expression([
        %Token{type: type} = identifier_token,
        %Token{type: :operator, data: %{category: :assignment, content: content}} = operator_token
        | remaining_tokens
      ])
      when type in [:store_variable, :identifier] do
    {right_token, next_tokens} =
      remaining_tokens
      |> generate_expression()
      |> get_expression_token()

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
        right: right_token,
        operator: content,
        category: :assignment
      )

    generate_expression([new_token | next_tokens])
  end

  # Manage arithmetic/logical operations
  def generate_expression([
        %Token{type: left_type} = left_token,
        %Token{type: :operator, data: %{category: operator_category, content: content}} =
          operator_token,
        %Token{type: right_type} = right_token
        | remaining_tokens
      ])
      when operator_category in [:arithmetic, :bitwise, :comparison] or content in ["&&", "||"] do
    new_token =
      Token.new(
        :expression,
        Interval.merge(left_token.interval, right_token.interval),
        left: left_token |> process_sub_token(),
        right: right_token |> process_sub_token(),
        operator: content,
        category: operator_category
      )

    generate_expression([new_token | remaining_tokens])
  end

  def generate_expression([
        %Token{type: :identifier} = identifier_token,
        %Token{type: :group, data: %{category: :parenthesis}} = arguments_token
        | remaining_tokens
      ]) do
    arguments =
      Token.get(arguments_token, :children, [])
      |> Js.rearrange_tokens()
      |> process_arguments()

    new_token =
      Token.new(
        :expression,
        Interval.merge(identifier_token.interval, arguments_token.interval),
        callee: identifier_token,
        arguments: arguments,
        category: :call
      )

    [new_token | remaining_tokens]
  end

  def generate_expression([
        %Token{type: :operator, data: %{content: "!"}} = operator_token,
        %Token{type: type} = argument_token
        | remaining_tokens
      ]) do
    new_token =
      Token.new(
        :expression,
        Interval.merge(operator_token.interval, argument_token.interval),
        argument: argument_token |> process_sub_token(),
        operator: "!",
        category: :unary
      )

    generate_expression([new_token | remaining_tokens])
  end

  defp error_on_condition(expression_token, tokens) do
    case tokens do
      [token | next_tokens] ->
        [
          Token.put(
            expression_token,
            :error,
            Error.new("unexpected token", interval: token.interval)
          )
          | next_tokens
        ]

      [] ->
        [
          Token.put(expression_token, :error, Error.new("missing consequent token"))
        ]
    end
  end

  def generate_expression([
        %Token{type: :expression, data: %{consequent: %Token{}, alternate: nil}} =
          expression_token
        | remaining_tokens
      ]) do
    case generate_expression(remaining_tokens) do
      [%Token{type: type} = alternate_token | next_tokens] when is_operand_type(type) ->
        [
          expression_token
          |> Token.put(:alternate, alternate_token)
          |> Token.put(
            :interval,
            Interval.merge(expression_token.interval, alternate_token.interval)
          )
          | next_tokens
        ]

      tokens ->
        error_on_condition(expression_token, tokens)
    end
  end

  def generate_expression([
        %Token{type: :expression, data: %{consequent: nil, alternate: nil}} = expression_token
        | remaining_tokens
      ]) do
    case generate_expression(remaining_tokens) do
      [
        %Token{type: type} = consequent_token,
        %Token{type: :operator, data: %{content: ":"}} = operator_token
        | next_tokens
      ]
      when is_operand_type(type) ->
        [
          expression_token
          |> Token.put(:consequent, consequent_token)
          |> Token.put(
            :interval,
            Interval.merge(expression_token.interval, consequent_token.interval)
          )
          | next_tokens
        ]
        |> generate_expression()

      [tokens] ->
        error_on_condition(expression_token, tokens)
    end
  end

  def generate_expression([
        %Token{type: type} = test_token,
        %Token{type: :operator, data: %{content: "?"}} = operator_token
        | remaining_tokens
      ])
      when is_operand_type(type) do
    new_token =
      Token.new(
        :expression,
        Interval.merge(test_token.interval, operator_token.interval),
        category: :conditional,
        test: test_token,
        consequent: nil,
        alternate: nil
      )

    generate_expression([new_token | remaining_tokens])
  end

  def generate_expression(tokens), do: tokens

  @impl Parser
  def rearrange(tokens), do: generate_expression(tokens)

  @impl Parser
  def check(%Token{type: :expression} = token) do
    Token.get(token, :left)
    |> Js.check_token()
    |> Enum.concat(Token.get(token, :right) |> Js.check_token())
    |> Enum.concat(Token.get(token, :arguments, []) |> Js.check_tokens())
    |> Enum.concat(Token.get(token, :argument) |> Js.check_token())
  end

  @impl Parser
  def check(_), do: []
end

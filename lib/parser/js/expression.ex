defmodule Origami.Parser.Js.Expression do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Error, Interval, Js, Token}

  @behaviour Parser

  defguardp is_operand_type(type) when type in [:number, :identifier, :expression]

  defp merge_operand_token(expression_token, [], _), do: [expression_token]

  defp merge_operand_token(
         expression_token,
         [%Token{type: :group, data: %{category: :parenthesis}} = group_token | next_tokens],
         key
       ) do
    [operand_token | _] = generate_expression([group_token])
    merge_operand_token(expression_token, [operand_token | next_tokens], key)
  end

  defp merge_operand_token(
         expression_token,
         [
           %Token{type: :identifier} = identifier_token,
           %Token{type: :operator, data: %{content: content}} = operator_token
           | next_tokens
         ],
         key
       )
       when content in ["++", "--"] do
    [operand_token | _] = generate_expression([identifier_token, operator_token])
    merge_operand_token(expression_token, [operand_token | next_tokens], key)
  end

  defp merge_operand_token(
         expression_token,
         [
           %Token{type: :operator, data: %{content: content}} = operator_token,
           %Token{type: :identifier} = identifier_token
           | next_tokens
         ],
         key
       )
       when content in ["++", "--"] do
    [operand_token | _] = generate_expression([operator_token, identifier_token])
    merge_operand_token(expression_token, [operand_token | next_tokens], key)
  end

  defp merge_operand_token(
         expression_token,
         [
           %Token{type: :operator, data: %{content: content}} = operator_token,
           %Token{type: type} = identifier_token
           | next_tokens
         ],
         key
       )
       when is_operand_type(type) and content in ["!", "+"] do
    [operand_token | _] = generate_expression([operator_token, identifier_token])
    merge_operand_token(expression_token, [operand_token | next_tokens], key)
  end

  defp merge_operand_token(
         expression_token,
         [
           %Token{type: :operator, data: %{content: content}} = operator_token,
           %Token{type: :group, data: %{category: :parenthesis}} = group_token
           | next_tokens
         ],
         key
       )
       when content in ["!", "+"] do
    [operand_token | _] = generate_expression([operator_token, group_token])
    merge_operand_token(expression_token, [operand_token | next_tokens], key)
  end

  defp merge_operand_token(
         expression_token,
         [%Token{type: type} = operand_token | next_tokens],
         key
       )
       when is_operand_type(type) do
    [
      expression_token
      |> Token.put(key, operand_token)
      |> Token.put(
        :interval,
        Interval.merge(expression_token.interval, operand_token.interval)
      )
      | next_tokens
    ]
    |> generate_expression()
  end

  defp merge_operand_token(
         expression_token,
         [token | next_tokens],
         key
       ) do
    [
      token |> Token.put(:error, Error.new("unexpected token"))
      | next_tokens
    ]
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

  def generate_expression([
        %Token{data: %{error: error}} = error_token,
        next_tokens | remaining_tokens
      ])
      when not is_nil(error) do
    [error_token, next_tokens | remaining_tokens]
  end

  def generate_expression([
        %Token{type: :identifier} = identifier_token,
        %Token{type: :operator, data: %{content: content}} = operator_token
        | remaining_tokens
      ])
      when content in ["++", "--"] do
    new_token =
      Token.new(
        :expression,
        Interval.merge(identifier_token.interval, operator_token.interval),
        prefix: false,
        argument: identifier_token,
        operator: content,
        category: :update
      )

    generate_expression([new_token | remaining_tokens])
  end

  def generate_expression([
        %Token{type: :operator, data: %{content: content}} = operator_token,
        %Token{type: :identifier} = identifier_token
        | remaining_tokens
      ])
      when content in ["++", "--"] do
    new_token =
      Token.new(
        :expression,
        Interval.merge(operator_token.interval, identifier_token.interval),
        prefix: true,
        argument: identifier_token,
        operator: content,
        category: :update
      )

    generate_expression([new_token | remaining_tokens])
  end

  def generate_expression([
        %Token{type: group, data: %{category: :parenthesis, children: children}} = group_token
        | remaining_tokens
      ]) do
    case generate_expression(children) do
      [token] ->
        [
          token
          |> Token.put(
            :interval,
            group_token.interval
          )
          | remaining_tokens
        ]
        |> generate_expression()

      _ ->
        [group_token |> Token.put(:error, Error.new("unexpected token")) | remaining_tokens]
    end
  end

  # Manage assignment a = value
  def generate_expression([
        %Token{type: type} = identifier_token,
        %Token{type: :operator, data: %{category: :assignment, content: content}} = operator_token
        | remaining_tokens
      ])
      when type in [:store_variable, :identifier] do
    expression_token =
      Token.new(
        :expression,
        Interval.merge(identifier_token.interval, operator_token.interval),
        left: identifier_token,
        operator: content,
        category: :assignment
      )

    merge_operand_token(
      expression_token,
      generate_expression(remaining_tokens),
      :right
    )
  end

  # Manage arithmetic/logical operations
  def generate_expression([
        %Token{type: left_type} = left_token,
        %Token{type: :operator, data: %{category: operator_category, content: content}} =
          operator_token
        | remaining_tokens
      ])
      when operator_category in [:arithmetic, :bitwise, :comparison] or
             (content in ["&&", "||"] and is_operand_type(left_type)) do
    expression_token =
      Token.new(
        :expression,
        Interval.merge(left_token.interval, operator_token.interval),
        left: left_token,
        operator: content,
        category: operator_category
      )

    merge_operand_token(
      expression_token,
      remaining_tokens,
      :right
    )
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

    generate_expression([new_token | remaining_tokens])
  end

  def generate_expression([
        %Token{type: :operator, data: %{content: content}} = operator_token
        | remaining_tokens
      ])
      when content in ["!", "+"] do
    expression_token =
      Token.new(
        :expression,
        operator_token.interval,
        operator: content,
        category: :unary
      )

    merge_operand_token(
      expression_token,
      remaining_tokens,
      :argument
    )
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

      tokens ->
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

  def generate_expression([
        %Token{type: :expression} = expression_token,
        %Token{type: type} = next_token
        | remaining_tokens
      ]) do
    case next_token do
      %Token{type: :punctuation, data: %{category: :semicolon}} ->
        [expression_token, next_token | remaining_tokens]

      %Token{type: :operator, data: %{category: category}}
      when category != :assignment ->
        [expression_token, next_token | remaining_tokens]

      _ ->
        if Js.same_line?([expression_token, next_token]) do
          error = Error.new("unexpected token")

          [
            expression_token,
            Token.put(next_token, :error, error)
            | remaining_tokens
          ]
        else
          [expression_token, next_token | remaining_tokens]
        end
    end
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

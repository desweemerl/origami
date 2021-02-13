defmodule Origami.Parser.Js.Declaration do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Interval, Token}
  alias Origami.Parser.Js.Expression

  @behaviour Parser

  defp fetch_declarator([
         %Token{type: :identifier} = identifier_token,
         %Token{type: :operator, data: %{content: "="}}
         | remaining_tokens
       ]) do
    case Expression.generate_expression(remaining_tokens) do
      [%Token{type: :expression} = expression_token | next_tokens] ->
        interval = Interval.merge(identifier_token.interval, expression_token.interval)

        new_token =
          Token.new(
            :identifier,
            interval,
            name: identifier_token.data.name,
            content: expression_token
          )

        {[new_token], next_tokens, interval}

      [%Token{} = value_token | next_tokens] ->
        interval = Interval.merge(identifier_token.interval, value_token.interval)

        new_token =
          Token.new(
            :identifier,
            interval,
            name: identifier_token.data.name,
            content: value_token
          )

        {[new_token], next_tokens, Interval.merge(new_token.interval, value_token.interval)}

      _ ->
        :nomatch
    end
  end

  defp fetch_declarator([%Token{type: :identifier} = identifier_token | remaining_tokens]) do
    {[identifier_token], remaining_tokens, identifier_token.interval}
  end

  defp fetch_declarator([
         %Token{type: :punctuation, data: %{category: :comma}, interval: interval}
         | remaining_tokens
       ]) do
    {[], remaining_tokens, interval}
  end

  defp fetch_declarator(_), do: :nomatch

  defp build_tokens(
         %Token{interval: parent_interval} = parent_token,
         remaining_tokens
       ) do
    case fetch_declarator(remaining_tokens) do
      :nomatch ->
        [parent_token | remaining_tokens]

      {identifier_token, next_tokens, interval} ->
        children = Token.get(parent_token, :children, [])

        parent_token
        |> Token.put(:children, children ++ identifier_token)
        |> Map.put(:interval, Interval.merge(parent_interval, interval))
        |> build_tokens(next_tokens)
    end
  end

  @impl Parser
  def rearrange([%Token{type: :keyword, data: %{name: name}, interval: interval} | next_tokens])
      when name in ["let", "const", "var"] do
    Token.new(:variable_declaration, interval, name: name)
    |> build_tokens(next_tokens)
  end

  @impl Parser
  def rearrange(tokens), do: tokens
end

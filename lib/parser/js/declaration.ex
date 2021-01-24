defmodule Origami.Parser.Js.Declaration do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Interval, Token}

  @behaviour Parser

  defp fetch_declarator([
         %Token{type: :identifier} = identifier_token,
         %Token{type: :operator, data: %{content: "="}},
         value_token | remaining_tokens
       ]) do
    new_token =
      Token.new(
        :identifier,
        interval: identifier_token.interval,
        data: %{
          name: identifier_token.data.name,
          content: value_token
        }
      )

    {[new_token], remaining_tokens, Interval.merge(new_token.interval, value_token.interval)}
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
         %Token{children: children, interval: parent_interval} = parent_token,
         remaining_tokens
       ) do
    case fetch_declarator(remaining_tokens) do
      :nomatch ->
        [parent_token | remaining_tokens]

      {identifier_token, next_tokens, interval} ->
        build_tokens(
          %Token{
            parent_token
            | children: children ++ identifier_token,
              interval: Interval.merge(parent_interval, interval)
          },
          next_tokens
        )
    end
  end

  @impl Parser
  def rearrange([%Token{type: :keyword, data: %{name: name}, interval: interval} | next_tokens])
      when name in ["let", "const", "var"] do
    build_tokens(
      Token.new(:variable_declaration, data: %{name: name}, interval: interval),
      next_tokens
    )
  end

  @impl Parser
  def rearrange(
        [%Token{interval: interval}, %Token{type: :operator, data: %{content: "="}} | _] = tokens
      ) do
    build_tokens(Token.new(:variable_declaration, interval: interval), tokens)
  end

  @impl Parser
  def rearrange(tokens), do: tokens
end

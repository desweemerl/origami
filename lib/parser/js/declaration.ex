defmodule Origami.Parser.Js.Declaration do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.Token

  @behaviour Parser

  defp fetch_declarator([
         %Token{type: :identifier} = identifier_token,
         %Token{type: :operator, content: "="},
         value_token | remaining_tokens
       ]) do
    new_token =
      Token.new(
        :identifier,
        name: identifier_token.name,
        interval: identifier_token.interval,
        content: value_token
      )

    {[new_token], remaining_tokens}
  end

  defp fetch_declarator([%Token{type: :identifier} = identifier_token | remaining_tokens]) do
    {[identifier_token], remaining_tokens}
  end

  defp fetch_declarator([%Token{type: :punctuation, category: :comma} | remaining_tokens]) do
    {[], remaining_tokens}
  end

  defp fetch_declarator(_), do: :nomatch

  defp build_tokens(%Token{children: children} = parent_token, remaining_tokens) do
    case fetch_declarator(remaining_tokens) do
      :nomatch ->
        [parent_token | remaining_tokens]

      {identifier_token, next_tokens} ->
        build_tokens(%Token{parent_token | children: children ++ identifier_token}, next_tokens)
    end
  end

  @impl Parser
  def rearrange([%Token{type: :keyword, name: name} | next_tokens])
      when name in ["let", "const", "var"] do
    parent_node = Token.new(:variable_declaration, name: name)
    build_tokens(parent_node, next_tokens)
  end

  @impl Parser
  def rearrange(tokens), do: tokens
end

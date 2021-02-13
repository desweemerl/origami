defmodule Origami.Parser.Js do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Syntax, Token}

  @behaviour Syntax

  @spec glued?(list(Token.t())) :: bool
  def glued?([]), do: false

  def glued?([_ | []]), do: false

  def glued?([
        %Token{interval: {_, _, stop_line, stop_col}}
        | [%Token{interval: {start_line, start_col, _, _}} | _]
      ]) do
    stop_line == start_line && stop_col + 1 == start_col
  end

  def end_line?([]), do: true

  def end_line?([_ | []]), do: true

  def end_line?([%Token{type: :punctuation, data: %{category: :semicolon}} | []]), do: true

  def end_line?([
        %Token{interval: {_, _, stop_line, _}} | [%Token{interval: {start_line, _, _, _}} | _]
      ]) do
    stop_line + 1 == start_line
  end

  def end_line?(_), do: false

  def rearrange_token(token), do: Parser.rearrange_token(token, rearrangers())

  def rearrange_tokens(tokens), do: Parser.rearrange_tokens(tokens, rearrangers())

  @impl Syntax
  def rearrangers() do
    [
      Origami.Parser.Js.Punctuation,
      Origami.Parser.Js.Number,
      Origami.Parser.Js.Expression,
      Origami.Parser.Js.Declaration,
      Origami.Parser.Js.Function,
      Origami.Parser.Js.Root
    ]
  end

  @impl Syntax
  def parsers() do
    [
      Origami.Parser.Js.Space,
      Origami.Parser.Js.Punctuation,
      Origami.Parser.Js.Comment,
      Origami.Parser.Js.CommentBlock,
      Origami.Parser.Js.Identifier,
      Origami.Parser.Js.Number,
      Origami.Parser.Js.Function,
      Origami.Parser.Js.Keyword,
      Origami.Parser.Js.OpenGroup,
      Origami.Parser.Js.CloseGroup,
      Origami.Parser.Js.String,
      Origami.Parser.Js.Operator,
      Origami.Parser.Js.StoreVar,
      Origami.Parser.Js.Unknown
    ]
  end
end

defmodule Origami.Parser.Js.Root do
  alias Origami.Parser
  alias Origami.Parser.{Token, Js}

  @behaviour Parser

  @impl Parser
  def rearrange([token | next_tokens] = tokens) do
    case Token.get(token, :children) do
      nil ->
        tokens

      children ->
        [
          Token.put(token, :children, Js.rearrange_tokens(children))
          | next_tokens
        ]
    end
  end

  @impl Parser
  def rearrange(tokens), do: tokens
end

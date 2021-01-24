defmodule Origami.Parser.Js do
  @moduledoc false

  alias Origami.Parser.{Syntax, Token}

  @behaviour Syntax

  @spec glued?(list(Token.t())) :: bool
  def glued?([]), do: false

  def glued?([_ | []]), do: false

  def glued?([token1 | [token2 | _]]) do
    token1.interval.stop.line == token2.interval.start.line &&
      token1.interval.stop.col + 1 == token2.interval.start.col
  end

  def end_line?([]), do: true

  def end_line?([_ | []]), do: true

  def end_line?([%Token{type: :punctuation, data: %{category: :semicolon}} | []]), do: true

  def end_line?([token1 | [token2 | _i]]) do
    token1.interval.stop.line + 1 == token2.interval.start.line
  end

  def end_line?(_), do: false

  @impl Syntax
  def rearrangers() do
    [
      Origami.Parser.Js.Number,
      Origami.Parser.Js.Declaration,
      Origami.Parser.Js.Punctuation
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
      Origami.Parser.Js.Keyword,
      # Origami.Parser.Js.Function,
      Origami.Parser.Js.OpenGroup,
      Origami.Parser.Js.CloseGroup,
      Origami.Parser.Js.String,
      Origami.Parser.Js.Operator,
      Origami.Parser.Js.StoreVar,
      Origami.Parser.Js.Unknown
    ]
  end
end

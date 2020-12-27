defmodule Origami.Parser.Js do
  @moduledoc false

  alias Origami.Parser.{Syntax, Token}

  @behaviour Syntax

  @spec glued?(list(Token.t())) :: bool
  def glued?([]), do: false

  def glued?([_ | []]), do: false

  def glued?([first_token | [next_token | _]]) do
    first_token.interval.stop.line == next_token.interval.start.line &&
      first_token.interval.stop.col + 1 == next_token.interval.start.col
  end

  @impl Syntax
  def rearrangers() do
    [
      Origami.Parser.Js.Number
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

defmodule Origami.Parser.Js do
  @moduledoc false

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

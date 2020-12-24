defmodule Origami.Parser.Js.CommentTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Error, Interval, Js, Position, Token}

  test "check if a single line comment is parsed" do
    text = "const a = 1 + 1; // This is a comment"

    child =
      text
      |> Parser.parse(parsers: Js.parsers())
      |> Token.last_child()

    {start, _} = :binary.match(text, "//")

    interval =
      Interval.new(
        Position.new(0, start),
        Position.new(0, String.length(text) - 1)
      )

    token =
      Token.new(
        :comment,
        interval: interval,
        content: " This is a comment"
      )

    assert token == child
  end

  test "check if a multiline comment is parsed" do
    text = """
    const a = 1 + 1; /* This is a
    multiline
    comment */
    """

    child =
      text
      |> Parser.parse(parsers: Js.parsers())
      |> Token.last_child()

    {start, _} = :binary.match(text, "/*")

    interval =
      Interval.new(
        Position.new(0, start),
        Position.new(2, 9)
      )

    token =
      Token.new(
        :comment_block,
        interval: interval,
        content: " This is a\nmultiline\ncomment "
      )

    assert token == child
  end

  test "check if parsing a unclosed multiline comment generates error" do
    text = """
    const a = 1 + 1; /* This is a
    multiline
    comment
    """

    child =
      text
      |> Parser.parse(parsers: Js.parsers())
      |> Token.last_child()

    {start, _} = :binary.match(text, "/*")

    interval =
      Interval.new(
        Position.new(0, start),
        Position.new(3, 0)
      )

    token =
      Token.new(
        :comment_block,
        interval: interval,
        error: Error.new("Unmatching comment block starting at 1:#{start + 1}")
      )

    assert token == child
  end
end

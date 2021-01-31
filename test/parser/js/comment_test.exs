defmodule Origami.Parser.Js.CommentTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Error, Interval, Js, Token}

  test "check if a single line comment is parsed" do
    text = "const a = 1 + 1; // This is a comment"

    {:ok, token} = Parser.parse(text, Js)
    child = Token.last_child(token)

    {start, _} = :binary.match(text, "//")

    token =
      Token.new(
        :comment,
        interval: Interval.new(0, start, 0, String.length(text) - 1),
        data: %{
          content: " This is a comment"
        }
      )

    assert token == child
  end

  test "check if a multiline comment is parsed" do
    text = """
    const a = 1 + 1; /* This is a
    multiline
    comment */
    """

    {:ok, token} = Parser.parse(text, Js)
    child = Token.last_child(token)

    {start, _} = :binary.match(text, "/*")

    token =
      Token.new(
        :comment_block,
        interval: Interval.new(0, start, 2, 9),
        data: %{
          content: " This is a\nmultiline\ncomment "
        }
      )

    assert token == child
  end

  test "check if parsing a unclosed multiline comment generates error" do
    text = """
    const a = 1 + 1; /* This is a
    multiline
    comment
    """

    {:error, errors} = Parser.parse(text, Js)

    {start, _} = :binary.match(text, "/*")

    assert [Error.new("Unmatching comment block starting at 1:#{start + 1}")] == errors
  end
end

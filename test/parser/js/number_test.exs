defmodule Origami.Parser.Js.NumberTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Error, Js, Position, Token}

  defp build_token(number, category, error \\ nil) do
    Token.new(
      :number,
      content: String.replace(number, " ", ""),
      category: category,
      error: error,
      start: Position.new(0, 0),
      stop: Position.new(0, String.length(number) - 1)
    )
  end

  test "Check if integer is parsed" do
    number = "12345"

    child =
      number
      |> Parser.parse(parsers: Js.parsers())
      |> Token.last_child()

    assert build_token(number, :integer) == child
  end

  test "Check if parsing wrong integer fails" do
    number = "12345abcde"

    %Token{children: [first_child | _]} =
      number
      |> Parser.parse(parsers: Js.parsers())

    assert build_token(number, :integer, Error.new("Unexpected token \"a\"")) == first_child
  end

  test "Check if negative integer is parsed (with spaces between minus and digits)" do
    number = "-   12345"

    child =
      number
      |> Parser.parse(parsers: Js.parsers())
      |> Token.last_child()

    assert build_token(number, :neg_integer) == child
  end

  test "Check if float is parsed" do
    number = "12345.123"

    child =
      number
      |> Parser.parse(parsers: Js.parsers())
      |> Token.last_child()

    assert build_token(number, :float) == child
  end

  test "Check if float is parsed (with spaces between minus and digits)" do
    number = "-    12345.123"

    child =
      number
      |> Parser.parse(parsers: Js.parsers())
      |> Token.last_child()

    assert build_token(number, :neg_float) == child
  end

  test "Check if float beginning with separator is parsed" do
    number = ".123"

    child =
      number
      |> Parser.parse(parsers: Js.parsers())
      |> Token.last_child()

    assert build_token(number, :float) == child
  end

  test "Check if float beginning with 2 separators generates error" do
    number = "..123"

    %Token{children: [first_child | _]} =
      number
      |> Parser.parse(parsers: Js.parsers())

    assert build_token(number, :float, Error.new("Unexpected token \".\"")) == first_child
  end

  test "Check if hexadecimal is parsed (uppercases)" do
    number = "0X0123456789ABCDEF"

    child =
      number
      |> Parser.parse(parsers: Js.parsers())
      |> Token.last_child()

    assert build_token(number, :hexadecimal) == child
  end

  test "Check if negative hexadecimal is parsed" do
    number = "-0x0123456789ABCDEF"

    child =
      number
      |> Parser.parse(parsers: Js.parsers())
      |> Token.last_child()

    assert build_token(number, :neg_hexadecimal) == child
  end

  test "Check if hexadecimal is parsed (lowercases)" do
    number = "0x0123456789abcdef"

    child =
      number
      |> Parser.parse(parsers: Js.parsers())
      |> Token.last_child()

    assert build_token(number, :hexadecimal) == child
  end

  test "Check if binary is parsed" do
    number = "0b11010101"

    child =
      number
      |> Parser.parse(parsers: Js.parsers())
      |> Token.last_child()

    assert build_token(number, :binary) == child
  end

  test "Check if negative binary is parsed" do
    number = "-0b11010101"

    child =
      number
      |> Parser.parse(parsers: Js.parsers())
      |> Token.last_child()

    assert build_token(number, :neg_binary) == child
  end
end

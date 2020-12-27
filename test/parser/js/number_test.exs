defmodule Origami.Parser.Js.NumberTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Error, Interval, Js, Position, Token}

  defp build_token(number, category, error \\ nil) do
    interval =
      Interval.new(
        Position.new(0, 0),
        Position.new(0, String.length(number) - 1)
      )

    Token.new(
      :number,
      content: String.replace(number, " ", ""),
      category: category,
      error: error,
      interval: interval
    )
  end

  test "check if integer is parsed" do
    number = "12345"

    child =
      number
      |> Parser.parse(Js)
      |> Token.last_child()

    assert build_token(number, :integer) == child
  end

  test "check if parsing wrong integer fails" do
    number = "12345abcde"

    %Token{children: [_ | [last_child]]} =
      number
      |> Parser.parse(Js)

    token =
      Token.new(
        :identifier,
        name: "abcde",
        error: Error.new("Unexpected token"),
        interval:
          Interval.new(
            Position.new(0, 5),
            Position.new(0, 9)
          )
      )

    assert token == last_child
  end

  test "check if negative integer is parsed (with spaces between minus and digits)" do
    number = "-   12345"

    child =
      number
      |> Parser.parse(Js)
      |> Token.last_child()

    assert build_token(number, :neg_integer) == child
  end

  test "check if float is parsed" do
    number = "12345.123"

    child =
      number
      |> Parser.parse(Js)
      |> Token.last_child()

    assert build_token(number, :float) == child
  end

  test "check if float is parsed (with spaces between minus and digits)" do
    number = "-    12345.123"

    child =
      number
      |> Parser.parse(Js)
      |> Token.last_child()

    assert build_token(number, :neg_float) == child
  end

  test "check if float beginning with separator is parsed" do
    number = ".123"

    child =
      number
      |> Parser.parse(Js)
      |> Token.last_child()

    assert build_token(number, :float) == child
  end

  test "check if parsing float beginning with 2 separators generates error" do
    number = "..123"

    %Token{children: [first_child | _]} =
      number
      |> Parser.parse(Js)

    assert build_token(number, :float, Error.new("Unexpected token \".\"")) == first_child
  end

  test "check if hexadecimal is parsed (uppercases)" do
    number = "0X0123456789ABCDEF"

    child =
      number
      |> Parser.parse(Js)
      |> Token.last_child()

    assert build_token(number, :hexadecimal) == child
  end

  test "check if negative hexadecimal is parsed" do
    number = "-0x0123456789ABCDEF"

    child =
      number
      |> Parser.parse(Js)
      |> Token.last_child()

    assert build_token(number, :neg_hexadecimal) == child
  end

  test "check if hexadecimal is parsed (lowercases)" do
    number = "0x0123456789abcdef"

    child =
      number
      |> Parser.parse(Js)
      |> Token.last_child()

    assert build_token(number, :hexadecimal) == child
  end

  test "check if binary is parsed" do
    number = "0b11010101"

    child =
      number
      |> Parser.parse(Js)
      |> Token.last_child()

    assert build_token(number, :binary) == child
  end

  test "check if negative binary is parsed" do
    number = "-0b11010101"

    child =
      number
      |> Parser.parse(Js)
      |> Token.last_child()

    assert build_token(number, :neg_binary) == child
  end
end

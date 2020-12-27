defmodule Origami.Parser.Js.PunctuationTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Js, Token, Interval, Position}

  test "check if comma/semicolon are parsed" do
    code = """
    let a, b;
    a = 1;
    """

    %Token{children: children} = Parser.parse(code, Js)
    [_, _, token1, _, token2, _, _, _, token3] = children

    assert token1 ==
             Token.new(
               :punctuation,
               category: :comma,
               interval:
                 Interval.new(
                   Position.new(0, 5),
                   Position.new(0, 5)
                 )
             )

    assert token2 ==
             Token.new(
               :punctuation,
               category: :semicolon,
               interval:
                 Interval.new(
                   Position.new(0, 8),
                   Position.new(0, 8)
                 )
             )

    assert token3 ==
             Token.new(
               :punctuation,
               category: :semicolon,
               interval:
                 Interval.new(
                   Position.new(1, 5),
                   Position.new(1, 5)
                 )
             )
  end
end

defmodule Origami.Parser.Js.FunctionTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Interval, Js, Token}

  test "check if named function is parsed" do
    function = """
    function test(a, b) {
      return a + b;
    }
    """

    {:ok, token} = Parser.parse(function, Js)
    children = Token.get(token, :children)

    expectation = [
      Token.new(
        :function,
        Interval.new(0, 0, 2, 0),
        name: "test",
        arguments: [
          Token.new(
            :identifier,
            Interval.new(0, 14, 0, 14),
            name: "a"
          ),
          Token.new(
            :identifier,
            Interval.new(0, 17, 0, 17),
            name: "b"
          )
        ],
        body: [
          Token.new(
            :keyword,
            Interval.new(1, 2, 1, 7),
            name: "return"
          ),
          Token.new(
            :expression,
            Interval.new(1, 9, 1, 13),
            category: :arithmetic,
            operator: "+",
            left:
              Token.new(
                :identifier,
                Interval.new(1, 9, 1, 9),
                name: "a"
              ),
            right:
              Token.new(
                :identifier,
                Interval.new(1, 13, 1, 13),
                name: "b"
              )
          )
        ]
      )
    ]

    assert expectation == children
  end
end

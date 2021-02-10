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

    {:ok, %Token{children: children}} = Parser.parse(function, Js)

    expectation = [
      Token.new(
        :function,
        interval: Interval.new(0, 0, 2, 0),
        data: %{
          name: "test",
          arguments: [
            Token.new(
              :identifier,
              interval: Interval.new(0, 14, 0, 14),
              data: %{
                name: "a"
              }
            ),
            Token.new(
              :identifier,
              interval: Interval.new(0, 17, 0, 17),
              data: %{
                name: "b"
              }
            )
          ],
          body: [
            Token.new(
              :keyword,
              interval: Interval.new(1, 2, 1, 7),
              data: %{name: "return"}
            ),
            Token.new(
              :expression,
              interval: Interval.new(1, 9, 1, 13),
              data: %{
                category: :arithmetic,
                operator: "+",
                left:
                  Token.new(
                    :identifier,
                    interval: Interval.new(1, 9, 1, 9),
                    data: %{name: "a"}
                  ),
                right:
                  Token.new(
                    :identifier,
                    interval: Interval.new(1, 13, 1, 13),
                    data: %{name: "b"}
                  )
              }
            )
          ]
        }
      )
    ]

    assert expectation == children
  end
end

defmodule Origami.Parser.Js.ExpressionTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Interval, Js, Token}

  test "check if simple binary expression is parsed" do
    expression = "1 + 2 + 3"

    {:ok, %Token{children: children}} = Parser.parse(expression, Js)

    expectation = [
      Token.new(
        :expression,
        interval: Interval.new(0, 0, 0, 8),
        data: %{
          category: :arithmetic,
          left:
            Token.new(
              :expression,
              interval: Interval.new(0, 0, 0, 4),
              data: %{
                category: :arithmetic,
                left:
                  Token.new(
                    :number,
                    interval: Interval.new(0, 0, 0, 0),
                    data: %{
                      category: :integer,
                      value: "1"
                    }
                  ),
                right:
                  Token.new(
                    :number,
                    interval: Interval.new(0, 4, 0, 4),
                    data: %{
                      category: :integer,
                      value: "2"
                    }
                  ),
                operator: "+"
              }
            ),
          right:
            Token.new(
              :number,
              interval: Interval.new(0, 8, 0, 8),
              data: %{
                category: :integer,
                value: "3"
              }
            ),
          operator: "+"
        }
      )
    ]

    assert expectation == children
  end

  test "check if grouped binary expressions are parsed" do
    expression = "1 + (2 + 3)"

    {:ok, %Token{children: children}} = Parser.parse(expression, Js)

    expectation = [
      Token.new(
        :expression,
        interval: Interval.new(0, 0, 0, 10),
        data: %{
          category: :arithmetic,
          left:
            Token.new(
              :number,
              interval: Interval.new(0, 0, 0, 0),
              data: %{
                category: :integer,
                value: "1"
              }
            ),
          right:
            Token.new(
              :group,
              interval: Interval.new(0, 4, 0, 10),
              data: %{category: :parenthesis},
              children: [
                Token.new(
                  :expression,
                  interval: Interval.new(0, 5, 0, 9),
                  data: %{
                    category: :arithmetic,
                    left:
                      Token.new(
                        :number,
                        interval: Interval.new(0, 5, 0, 5),
                        data: %{
                          category: :integer,
                          value: "2"
                        }
                      ),
                    right:
                      Token.new(
                        :number,
                        interval: Interval.new(0, 9, 0, 9),
                        data: %{
                          category: :integer,
                          value: "3"
                        }
                      ),
                    operator: "+"
                  }
                )
              ]
            ),
          operator: "+"
        }
      )
    ]

    assert expectation == children
  end

  test "check if mixed assignment/arithmeric expression is parsed" do
    expression = "a += 1 + 2"

    {:ok, %Token{children: children}} = Parser.parse(expression, Js)

    expectation = [
      Token.new(
        :expression,
        interval: Interval.new(0, 0, 0, 9),
        data: %{
          category: :assignment,
          operator: "+=",
          left:
            Token.new(
              :identifier,
              interval: Interval.new(0, 0, 0, 0),
              data: %{
                name: "a"
              }
            ),
          right:
            Token.new(
              :expression,
              interval: Interval.new(0, 5, 0, 9),
              data: %{
                category: :arithmetic,
                left:
                  Token.new(
                    :number,
                    interval: Interval.new(0, 5, 0, 5),
                    data: %{
                      category: :integer,
                      value: "1"
                    }
                  ),
                right:
                  Token.new(
                    :number,
                    interval: Interval.new(0, 9, 0, 9),
                    data: %{
                      category: :integer,
                      value: "2"
                    }
                  ),
                operator: "+"
              }
            )
        }
      )
    ]

    assert expectation == children
  end
end

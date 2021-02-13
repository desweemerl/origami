defmodule Origami.Parser.Js.ExpressionTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Interval, Js, Token}

  test "check if simple binary expression is parsed" do
    expression = "1 + 2 + 3"

    {:ok, token} = Parser.parse(expression, Js)
    children = Token.get(token, :children)

    expectation = [
      Token.new(
        :expression,
        Interval.new(0, 0, 0, 8),
        category: :arithmetic,
        left:
          Token.new(
            :expression,
            Interval.new(0, 0, 0, 4),
            category: :arithmetic,
            left:
              Token.new(
                :number,
                Interval.new(0, 0, 0, 0),
                category: :integer,
                value: "1"
              ),
            right:
              Token.new(
                :number,
                Interval.new(0, 4, 0, 4),
                category: :integer,
                value: "2"
              ),
            operator: "+"
          ),
        right:
          Token.new(
            :number,
            Interval.new(0, 8, 0, 8),
            category: :integer,
            value: "3"
          ),
        operator: "+"
      )
    ]

    assert expectation == children
  end

  test "check if grouped binary expressions are parsed" do
    expression = "1 + (2 + 3)"

    {:ok, token} = Parser.parse(expression, Js)
    children = Token.get(token, :children)

    expectation = [
      Token.new(
        :expression,
        Interval.new(0, 0, 0, 10),
        category: :arithmetic,
        left:
          Token.new(
            :number,
            Interval.new(0, 0, 0, 0),
            category: :integer,
            value: "1"
          ),
        right:
          Token.new(
            :group,
            Interval.new(0, 4, 0, 10),
            category: :parenthesis,
            children: [
              Token.new(
                :expression,
                Interval.new(0, 5, 0, 9),
                category: :arithmetic,
                left:
                  Token.new(
                    :number,
                    Interval.new(0, 5, 0, 5),
                    category: :integer,
                    value: "2"
                  ),
                right:
                  Token.new(
                    :number,
                    Interval.new(0, 9, 0, 9),
                    category: :integer,
                    value: "3"
                  ),
                operator: "+"
              )
            ]
          ),
        operator: "+"
      )
    ]

    assert expectation == children
  end

  test "check if mixed assignment/arithmeric expression is parsed" do
    expression = "a += 1 + 2"

    {:ok, token} = Parser.parse(expression, Js)
    children = Token.get(token, :children)

    expectation = [
      Token.new(
        :expression,
        Interval.new(0, 0, 0, 9),
        category: :assignment,
        operator: "+=",
        left:
          Token.new(
            :identifier,
            Interval.new(0, 0, 0, 0),
            name: "a"
          ),
        right:
          Token.new(
            :expression,
            Interval.new(0, 5, 0, 9),
            category: :arithmetic,
            left:
              Token.new(
                :number,
                Interval.new(0, 5, 0, 5),
                category: :integer,
                value: "1"
              ),
            right:
              Token.new(
                :number,
                Interval.new(0, 9, 0, 9),
                category: :integer,
                value: "2"
              ),
            operator: "+"
          )
      )
    ]

    assert expectation == children
  end

  test "check if mixed store variable expression is parsed" do
    expression = "@a = 1 + 2"

    {:ok, token} = Parser.parse(expression, Js)
    children = Token.get(token, :children)

    expectation = [
      Token.new(
        :expression,
        Interval.new(0, 0, 0, 9),
        category: :assignment,
        operator: "=",
        left:
          Token.new(
            :store_variable,
            Interval.new(0, 0, 0, 1),
            name: "a"
          ),
        right:
          Token.new(
            :expression,
            Interval.new(0, 5, 0, 9),
            category: :arithmetic,
            left:
              Token.new(
                :number,
                Interval.new(0, 5, 0, 5),
                category: :integer,
                value: "1"
              ),
            right:
              Token.new(
                :number,
                Interval.new(0, 9, 0, 9),
                category: :integer,
                value: "2"
              ),
            operator: "+"
          )
      )
    ]

    assert expectation == children
  end
end

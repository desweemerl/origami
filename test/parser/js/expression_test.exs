defmodule Origami.Parser.Js.ExpressionTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Error, Interval, Js, Token}

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
            :expression,
            Interval.new(0, 4, 0, 10),
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

  test "check if wrong char in expression generates error" do
    expression = "a = 1 + /"

    {:error, [error]} = Parser.parse(expression, Js)

    assert Error.new("unexpected token", interval: Interval.new(0, 8, 0, 8)) == error
  end

  test "check if call is parsed" do
    expression = "test(a + 1, b)"

    {:ok, token} = Parser.parse(expression, Js)
    children = Token.get(token, :children)

    expectation = [
      Token.new(
        :expression,
        Interval.new(0, 0, 0, 13),
        category: :call,
        callee: Token.new(:identifier, Interval.new(0, 0, 0, 3), name: "test"),
        arguments: [
          Token.new(
            :expression,
            Interval.new(0, 5, 0, 9),
            category: :arithmetic,
            operator: "+",
            left: Token.new(:identifier, Interval.new(0, 5, 0, 5), name: "a"),
            right: Token.new(:number, Interval.new(0, 9, 0, 9), value: "1", category: :integer)
          ),
          Token.new(:identifier, Interval.new(0, 12, 0, 12), name: "b")
        ]
      )
    ]

    assert expectation == children
  end

  test "check if unary expression is parsed" do
    expression = "!(a || b)"

    {:ok, token} = Parser.parse(expression, Js)
    children = Token.get(token, :children)

    expectation = [
      Token.new(
        :expression,
        Interval.new(0, 0, 0, 8),
        category: :unary,
        operator: "!",
        argument:
          Token.new(
            :expression,
            Interval.new(0, 1, 0, 8),
            category: :logical,
            operator: "||",
            left:
              Token.new(
                :identifier,
                Interval.new(0, 2, 0, 2),
                name: "a"
              ),
            right:
              Token.new(
                :identifier,
                Interval.new(0, 7, 0, 7),
                name: "b"
              )
          )
      )
    ]

    assert expectation == children
  end

  test "check if ternary expression is parsed" do
    expression = "!a ? 1 : 2"

    {:ok, token} = Parser.parse(expression, Js)
    children = Token.get(token, :children)

    expectation = [
      Token.new(
        :expression,
        Interval.new(0, 0, 0, 9),
        category: :conditional,
        test:
          Token.new(
            :expression,
            Interval.new(0, 0, 0, 1),
            category: :unary,
            operator: "!",
            argument:
              Token.new(
                :identifier,
                Interval.new(0, 1, 0, 1),
                name: "a"
              )
          ),
        consequent:
          Token.new(
            :number,
            Interval.new(0, 5, 0, 5),
            category: :integer,
            value: "1"
          ),
        alternate:
          Token.new(
            :number,
            Interval.new(0, 9, 0, 9),
            category: :integer,
            value: "2"
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

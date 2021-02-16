defmodule Origami.Parser.Js.DeclarationTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Interval, Js, Token}

  test "check if single declarations are parsed" do
    declaration = """
    var a = 1;
    let b = 1;
    const c = 1;
    """

    {:ok, token} = Parser.parse(declaration, Js)
    children = Token.get(token, :children)

    expectation = [
      Token.new(
        :variable_declaration,
        Interval.new(0, 0, 0, 8),
        name: "var",
        children: [
          Token.new(
            :identifier,
            Interval.new(0, 4, 0, 8),
            name: "a",
            content:
              Token.new(
                :number,
                Interval.new(0, 8, 0, 8),
                category: :integer,
                value: "1"
              )
          )
        ]
      ),
      Token.new(
        :variable_declaration,
        Interval.new(1, 0, 1, 8),
        name: "let",
        children: [
          Token.new(
            :identifier,
            Interval.new(1, 4, 1, 8),
            name: "b",
            content:
              Token.new(
                :number,
                Interval.new(1, 8, 1, 8),
                category: :integer,
                value: "1"
              )
          )
        ]
      ),
      Token.new(
        :variable_declaration,
        Interval.new(2, 0, 2, 10),
        name: "const",
        children: [
          Token.new(
            :identifier,
            Interval.new(2, 6, 2, 10),
            name: "c",
            content:
              Token.new(
                :number,
                Interval.new(2, 10, 2, 10),
                category: :integer,
                value: "1"
              )
          )
        ]
      )
    ]

    assert expectation == children
  end

  test "check if expression is parsed in declaration" do
    declaration = "let a = (b + 1) / 3"

    {:ok, token} = Parser.parse(declaration, Js)
    children = Token.get(token, :children)

    expectation = [
      Token.new(
        :variable_declaration,
        Interval.new(0, 0, 0, 18),
        name: "let",
        children: [
          Token.new(
            :identifier,
            Interval.new(0, 4, 0, 18),
            name: "a",
            content:
              Token.new(
                :expression,
                Interval.new(0, 8, 0, 18),
                category: :arithmetic,
                operator: "/",
                left:
                  Token.new(
                    :expression,
                    Interval.new(0, 8, 0, 14),
                    category: :arithmetic,
                    operator: "+",
                    left:
                      Token.new(
                        :identifier,
                        Interval.new(0, 9, 0, 9),
                        name: "b"
                      ),
                    right:
                      Token.new(
                        :number,
                        Interval.new(0, 13, 0, 13),
                        category: :integer,
                        value: "1"
                      )
                  ),
                right:
                  Token.new(
                    :number,
                    Interval.new(0, 18, 0, 18),
                    category: :integer,
                    value: "3"
                  )
              )
          )
        ]
      )
    ]

    assert expectation == children
  end
end

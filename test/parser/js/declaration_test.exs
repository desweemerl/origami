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

    {:ok, %Token{children: children}} = Parser.parse(declaration, Js)

    expectation = [
      Token.new(
        :variable_declaration,
        interval: Interval.new(0, 0, 0, 8),
        data: %{
          name: "var"
        },
        children: [
          Token.new(
            :identifier,
            interval: Interval.new(0, 4, 0, 8),
            data: %{
              name: "a",
              content:
                Token.new(
                  :number,
                  interval: Interval.new(0, 8, 0, 8),
                  data: %{
                    category: :integer,
                    value: "1"
                  }
                )
            }
          )
        ]
      ),
      Token.new(
        :variable_declaration,
        interval: Interval.new(1, 0, 1, 8),
        data: %{
          name: "let"
        },
        children: [
          Token.new(
            :identifier,
            interval: Interval.new(1, 4, 1, 8),
            data: %{
              name: "b",
              content:
                Token.new(
                  :number,
                  interval: Interval.new(1, 8, 1, 8),
                  data: %{
                    category: :integer,
                    value: "1"
                  }
                )
            }
          )
        ]
      ),
      Token.new(
        :variable_declaration,
        interval: Interval.new(2, 0, 2, 10),
        data: %{
          name: "const"
        },
        children: [
          Token.new(
            :identifier,
            interval: Interval.new(2, 6, 2, 10),
            data: %{
              name: "c",
              content:
                Token.new(
                  :number,
                  interval: Interval.new(2, 10, 2, 10),
                  data: %{
                    category: :integer,
                    value: "1"
                  }
                )
            }
          )
        ]
      )
    ]

    assert expectation == children
  end

  test "check if expression is parsed in declaration" do
    declaration = "let a = (b + 1) / 3"

    {:ok, %Token{children: children}} = Parser.parse(declaration, Js)

    expectation = [
      Token.new(
        :variable_declaration,
        interval: Interval.new(0, 0, 0, 18),
        data: %{
          name: "let"
        },
        children: [
          Token.new(
            :identifier,
            interval: Interval.new(0, 4, 0, 18),
            data: %{
              name: "a",
              content:
                Token.new(
                  :expression,
                  interval: Interval.new(0, 8, 0, 18),
                  data: %{
                    category: :arithmetic,
                    operator: "/",
                    left:
                      Token.new(
                        :group,
                        interval: Interval.new(0, 8, 0, 14),
                        data: %{category: :parenthesis},
                        children: [
                          Token.new(
                            :expression,
                            interval: Interval.new(0, 9, 0, 13),
                            data: %{
                              category: :arithmetic,
                              operator: "+",
                              left:
                                Token.new(
                                  :identifier,
                                  interval: Interval.new(0, 9, 0, 9),
                                  data: %{name: "b"}
                                ),
                              right:
                                Token.new(
                                  :number,
                                  interval: Interval.new(0, 13, 0, 13),
                                  data: %{
                                    category: :integer,
                                    value: "1"
                                  }
                                )
                            }
                          )
                        ]
                      ),
                    right:
                      Token.new(
                        :number,
                        interval: Interval.new(0, 18, 0, 18),
                        data: %{
                          category: :integer,
                          value: "3"
                        }
                      )
                  }
                )
            }
          )
        ]
      )
    ]

    assert expectation == children
  end
end

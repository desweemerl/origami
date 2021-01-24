defmodule Origami.Parser.Js.IdentifierTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Error, Interval, Js, Token}

  test "check if identifier with only letters is parsed" do
    identifier = "aIdentifier"

    child =
      identifier
      |> Parser.parse(Js)
      |> Token.last_child()

    token =
      Token.new(
        :identifier,
        interval: Interval.new(0, 0, 0, String.length(identifier) - 1),
        data: %{
          name: identifier
        }
      )

    assert token == child
  end

  test "check if parsing an identifier starting with digit fails" do
    identifier = "1aIdentifier"

    child =
      identifier
      |> Parser.parse(Js)
      |> Token.last_child()

    token =
      Token.new(
        :identifier,
        interval: Interval.new(0, 1, 0, String.length(identifier) - 1),
        error: Error.new("Unexpected token"),
        data: %{
          name: "aIdentifier"
        }
      )

    assert token == child
  end
end

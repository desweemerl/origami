defmodule Origami.Parser.Js.IdentifierTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Error, Interval, Js, Token}

  defp build_token(identifier) do
    Token.new(
      :identifier,
      Interval.new(0, 0, 0, String.length(identifier) - 1),
      name: identifier
    )
  end

  test "check if identifier with only letters is parsed" do
    identifier = "aIdentifier"

    {:ok, token} = Parser.parse(identifier, Js)
    child = Token.last_child(token)

    assert build_token(identifier) == child
  end

  test "check if parsing an identifier starting with digit fails" do
    identifier = "1aIdentifier"

    {:error, errors} = Parser.parse(identifier, Js)

    expected_error =
      Error.new(
        "Unexpected token",
        interval: Interval.new(0, 1, 0, 11)
      )

    assert [expected_error] == errors
  end
end

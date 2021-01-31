defmodule Origami.Parser.Js.IdentifierTest do
  use ExUnit.Case

  alias Origami.Parser
  alias Origami.Parser.{Error, Interval, Js, Token}

  defp build_token(identifier) do
    Token.new(
      :identifier,
      interval: Interval.new(0, 0, 0, String.length(identifier) - 1),
      data: %{
        name: identifier
      }
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

    assert [Error.new("Unexpected token")] == errors
  end
end

defmodule Origami.Parser.Js.Keyword do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Token}

  @start_keywords ~w(NaN Infinity with super debugger continue try throw return var let
    const if switch case default for while break function import export delete)
  @other_keywords ~w(null this do in instanceof of else get set new catch finally typeof
    yield async await from as extends)
  @keywords @start_keywords ++ @other_keywords

  def keyword?(value), do: value in @keywords

  defmacro keywords do
    quote do
      @keywords
      |> Enum.sort(&(String.length(&1) >= String.length(&2)))
    end
  end

  @behaviour Parser

  @impl Parser
  def consume(buffer, token) do
    case keywords()
         |> Enum.find(&Buffer.check_chars(buffer, &1)) do
      nil ->
        :nomatch

      chars ->
        new_buffer = Buffer.consume_chars(buffer, String.length(chars))

        new_token =
          Token.new(
            :keyword,
            Buffer.interval(buffer, new_buffer),
            name: chars
          )

        {
          :cont,
          new_buffer,
          Token.concat(token, new_token)
        }
    end
  end
end

defmodule Origami.Parser.Js.Space do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.Buffer

  @behaviour Parser

  def space?(<<c>>), do: c in [?\s, ?\r, ?\n, ?\t]

  @impl Parser
  def consume(buffer, token) do
    case Buffer.get_char(buffer)
         |> space?() do
      # Don't generate token for spaces
      true ->
        {
          :cont,
          Buffer.consume_char(buffer),
          token
        }

      _ ->
        :nomatch
    end
  end
end

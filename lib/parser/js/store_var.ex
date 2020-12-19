defmodule Origami.Parser.Js.StoreVar do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Error, Token}
  alias Origami.Parser.Js.Identifier

  @behaviour Parser

  @impl Parser
  def consume(buffer, token) do
    case Buffer.check_chars(buffer, "@") do
      true ->
        new_buffer = Buffer.consume_char(buffer)

        case Identifier.get_identifier(new_buffer) do
          {_, ""} ->
            new_token =
              Token.new(
                :store_var,
                start: Buffer.position(buffer),
                stop: Buffer.position(new_buffer),
                error: Error.new("Missing identifier")
              )

            {
              :cont,
              new_buffer,
              Token.concat(token, new_token)
            }

          {identifier_buffer, name} ->
            new_token =
              Token.new(
                :store_var,
                start: Buffer.position(buffer),
                stop: Buffer.position(identifier_buffer),
                name: name
              )

            {
              :cont,
              identifier_buffer,
              Token.concat(token, new_token)
            }
        end

      _ ->
        :nomatch
    end
  end
end

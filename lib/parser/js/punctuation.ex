defmodule Origami.Parser.Js.Punctuation do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Token}

  @behaviour Parser

  def punctuation_type(<<c>>) do
    case c do
      ?, -> :comma
      ?; -> :semicolon
      _ -> :unknown
    end
  end

  @impl Parser
  def consume(buffer, token) do
    case buffer
         |> Buffer.get_char()
         |> punctuation_type() do
      :unknown ->
        :nomatch

      type ->
        new_buffer = Buffer.consume_char(buffer)

        new_token =
          Token.new(
            :punctuation,
            interval: Buffer.interval(buffer, new_buffer),
            category: type
          )

        {
          :cont,
          new_buffer,
          Token.concat(token, new_token)
        }
    end
  end
end

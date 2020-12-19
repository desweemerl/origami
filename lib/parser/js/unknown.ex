defmodule Origami.Parser.Js.Unknown do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Token}

  @behaviour Parser

  @impl Parser
  def consume(buffer, token) do
    {char, new_buffer} = Buffer.next_char(buffer)

    new_token =
      Token.new(
        :unknown,
        start: Buffer.position(buffer),
        stop: Buffer.position(new_buffer),
        content: char
      )

    {
      :cont,
      new_buffer,
      Token.merge_content(token, new_token)
    }
  end
end

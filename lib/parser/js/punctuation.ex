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
    {char, new_buffer} = Buffer.get_char(buffer)

    case punctuation_type(char) do
      :unknown ->
        :nomatch

      type ->
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

  @impl Parser
  def rearrange([%Token{type: :punctuation, category: :semicolon} | _]), do: :drop

  @impl Parser
  def rearrange(tokens), do: tokens
end

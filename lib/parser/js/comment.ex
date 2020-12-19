defmodule Origami.Parser.Js.Comment do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Position, Token}

  @behaviour Parser

  @impl Parser
  def consume(buffer, token) do
    case Buffer.check_chars(buffer, "//") do
      true ->
        # Get the remaining content on the current line
        {content, new_buffer} =
          buffer
          |> Buffer.consume_chars(2)
          |> Buffer.next_chars(-1)

        start = Buffer.position(buffer)

        new_token =
          Token.new(
            :comment,
            start: start,
            stop: Position.add_length(start, content),
            content: content
          )

        {
          :cont,
          new_buffer,
          Token.concat(token, new_token)
        }

      _ ->
        :nomatch
    end
  end
end

defmodule Origami.Parser.Js.CommentBlock do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Error, Token}

  @behaviour Parser

  @impl Parser
  def consume(buffer, token) do
    start = Buffer.position(buffer)

    case Buffer.check_chars(buffer, "/*") do
      true ->
        {new_token, new_buffer} =
          case buffer
               |> Buffer.consume_chars(2)
               |> Buffer.chars_until("*/", scope_line: false, exclude_chars: true) do
            :nomatch ->
              {
                Token.new(
                  :comment_block,
                  start: start,
                  error: Error.new("Unmatching comment block starting at #{start}")
                ),
                Buffer.consume_lines(buffer, -1)
                # Consume remaining lines in the buffer
              }

            {content, new_buffer} ->
              {
                Token.new(
                  :comment_block,
                  start: start,
                  stop: Buffer.position(new_buffer),
                  content: content
                ),
                new_buffer
              }
          end

        {
          :cont,
          new_buffer,
          Token.concat(token, new_token)
        }

      _ ->
        :nomatch
    end
  end
end

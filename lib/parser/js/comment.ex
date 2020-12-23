defmodule Origami.Parser.Js.Comment do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Token}

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

        new_token =
          Token.new(
            :comment,
            interval: Buffer.interval(buffer, new_buffer),
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
              remaining_buffer = Buffer.consume_lines(buffer, -1)

              {
                Token.new(
                  :comment_block,
                  interval: Buffer.interval(buffer, remaining_buffer),
                  error: Error.new("Unmatching comment block starting at #{start}")
                ),
                remaining_buffer
              }

            {content, new_buffer} ->
              {
                Token.new(
                  :comment_block,
                  interval: Buffer.interval(buffer, new_buffer),
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

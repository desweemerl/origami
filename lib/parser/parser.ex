defmodule Origami.Parser do
  alias Origami.Parser.{Buffer, Token}

  @callback consume(Buffer.t(), Token.t()) ::
              :nomatch | {:cont, Buffer.t(), Token.t()} | {:halt, Buffer.t(), Token.t()}

  @callback rearrange(list(Token.t())) :: list(Token.t())

  @optional_callbacks consume: 2, rearrange: 1

  @spec parse(any, module) :: Token.t()
  def parse(source, syntax, options \\ []) do
    buffer = Buffer.from(source, options)

    parse_buffer(syntax.parsers, buffer, Token.new(:root))
    |> rearrange_token(syntax.rearrangers)
  end

  def parse_buffer(parsers, buffer, token) do
    cond do
      Buffer.over?(buffer) ->
        token

      Buffer.end_line?(buffer) ->
        parse_buffer(parsers, Buffer.consume_line(buffer), token)

      true ->
        case parse_next(parsers, buffer, token) do
          {:halt, new_buffer, new_tree} ->
            {new_buffer, new_tree}

          {:cont, new_buffer, new_tree} ->
            parse_buffer(parsers, new_buffer, new_tree)
        end
    end
  end

  defp rearrange_token(token, []), do: token

  defp rearrange_token(token, rearrangers) do
    case token.children do
      [] ->
        token

      children ->
        %Token{token | children: rearrange_tokens(children, rearrangers)}
    end
  end

  defp rearrange_tokens([], _), do: []

  defp rearrange_tokens([first_token | remaining_tokens], rearrangers) do
    [new_first_token | new_remaining_tokens] =
      rearrange_next(
        [rearrange_token(first_token, rearrangers) | remaining_tokens],
        rearrangers
      )

    [new_first_token | rearrange_tokens(new_remaining_tokens, rearrangers)]
  end

  defp rearrange_next([], _), do: []

  defp rearrange_next(tokens, []), do: tokens

  defp rearrange_next(tokens, [rearranger | rearrangers]) do
    new_tokens =
      cond do
        is_function(&rearranger.rearrange/1) ->
          rearranger.rearrange(tokens)

        true ->
          tokens
      end

    rearrange_next(new_tokens, rearrangers)
  end

  defp parse_next([], buffer, _) do
    raise "Can't find parser to process line: #{Buffer.current_line(buffer)}"
  end

  defp parse_next([parser | parsers], buffer, token) do
    cond do
      is_function(&parser.consume/2) ->
        case parser.consume(buffer, token) do
          :nomatch ->
            parse_next(parsers, buffer, token)

          result ->
            result
        end

      true ->
        parse_next(parsers, buffer, token)
    end
  end
end

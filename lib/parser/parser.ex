defmodule Origami.Parser do
  alias Origami.Parser.{Buffer, Error, Token}

  @callback consume(Buffer.t(), Token.t()) ::
              :nomatch | {:cont, Buffer.t(), Token.t()} | {:halt, Buffer.t(), Token.t()}

  @callback rearrange(list(Token.t())) :: list(Token.t())

  @optional_callbacks consume: 2, rearrange: 1

  defp aggregate_errors(%Token{interval: interval} = token) do
    errors =
      case Token.get(token, :error) do
        nil ->
          []

        error ->
          [%Error{error | interval: interval}]
      end

    (Token.get(token, :children, []) |> Enum.flat_map(&aggregate_errors/1)) ++ errors
  end

  defp to_result({_, token}), do: to_result(token)

  defp to_result(token) when is_struct(token) do
    case aggregate_errors(token) do
      [] ->
        {:ok, token}

      errors ->
        {:error, errors}
    end
  end

  @spec parse(any, module) :: Token.t()
  def parse(source, syntax, options \\ []) do
    buffer = Buffer.from(source, options)

    case parse_buffer(buffer, Token.new(:root), syntax.parsers()) |> to_result() do
      {:ok, token} ->
        rearrange_token(token, syntax.rearrangers) |> to_result()

      errors ->
        errors
    end
  end

  def parse_buffer(buffer, token, parsers) do
    cond do
      Buffer.over?(buffer) ->
        {buffer, token}

      Buffer.end_line?(buffer) ->
        parse_buffer(Buffer.consume_line(buffer), token, parsers)

      true ->
        case parse_next(buffer, token, parsers) do
          {:halt, new_buffer, new_tree} ->
            {new_buffer, new_tree}

          {:cont, new_buffer, new_tree} ->
            parse_buffer(new_buffer, new_tree, parsers)
        end
    end
  end

  defp parse_next(buffer, _, []) do
    raise "Can't find parser to process line: #{Buffer.current_line(buffer)}"
  end

  defp parse_next(buffer, token, [parser | parsers]) do
    case parser.consume(buffer, token) do
      :nomatch ->
        parse_next(buffer, token, parsers)

      result ->
        result
    end
  end

  def rearrange_token(token, []) when is_struct(token), do: token

  def rearrange_token(token, rearrangers) when is_struct(token) do
    case rearrange_tokens([token], rearrangers) do
      [] ->
        token

      [new_token | _] ->
        new_token
    end
  end

  def rearrange_tokens([], _), do: []

  def rearrange_tokens([_ | remaining_tokens] = tokens, rearrangers) do
    case rearrange_next(tokens, rearrangers) do
      :drop ->
        rearrange_tokens(remaining_tokens, rearrangers)

      [new_first_token | new_remaining_tokens] ->
        [new_first_token | rearrange_tokens(new_remaining_tokens, rearrangers)]

      others ->
        others
    end
  end

  defp rearrange_next([], _), do: []

  defp rearrange_next(tokens, []), do: tokens

  defp rearrange_next(tokens, [rearranger | rearrangers]) do
    case rearranger.rearrange(tokens) do
      :drop ->
        :drop

      new_tokens ->
        rearrange_next(new_tokens, rearrangers)
    end
  end
end

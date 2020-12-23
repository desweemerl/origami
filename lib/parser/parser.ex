defprotocol Origami.Parser.Match do
  alias Origami.Parser

  @type t() :: :match | :nomatch

  @spec to_match(t) :: t()
  def to_match(value)
end

defimpl Origami.Parser.Match, for: Atom do
  def to_match(value), do: if(value, do: :match, else: :nomatch)
end

defmodule Origami.Parser do
  alias Origami.Parser.{Buffer, Token}

  @callback consume(Buffer.t(), Token.t()) ::
              :nomatch | {:cont, Buffer.t(), Token.t()} | {:halt, Buffer.t(), Token.t()}

  @optional_callbacks consume: 2

  def parse(source, options \\ []) do
    buffer = Buffer.from(source, options)
    parsers = Keyword.get(options, :parsers, [])

    parse_buffer(parsers, buffer, Token.new(:root))
  end

  def parse_buffer(parsers, buffer, token) do
    cond do
      Buffer.over?(buffer) ->
        token

      Buffer.end_line?(buffer) ->
        parse_buffer(parsers, Buffer.consume_line(buffer), token)

      true ->
        case step_into(parsers, buffer, token) do
          {:halt, new_buffer, new_tree} ->
            {new_buffer, new_tree}

          {:cont, new_buffer, new_tree} ->
            parse_buffer(parsers, new_buffer, new_tree)
        end
    end
  end

  defp step_into([], buffer, _) do
    raise "Can't find parser to process line: #{Buffer.current_line(buffer)}"
  end

  defp step_into([parser | parsers], buffer, token) do
    case parser.consume(buffer, token) do
      :nomatch ->
        step_into(parsers, buffer, token)

      result ->
        result
    end
  end
end

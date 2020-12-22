defmodule Origami.Parser.Js.Group do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Error, Js, Token}

  def bracket_parser() do
    [
      Origami.Parser.Js.Space,
      Origami.Parser.Js.Punctuation,
      Origami.Parser.Js.OpenGroup,
      Origami.Parser.Js.CloseGroup,
      Origami.Parser.Js.Identifier,
      Origami.Parser.Js.Number,
      Origami.Parser.Js.Keyword,
      Origami.Parser.Js.Operator,
      Origami.Parser.Js.Unknown
    ]
  end

  defguard is_empty(value) when is_nil(value) or value == ""

  def close_group?(c) when is_empty(c), do: false
  def close_group?(<<c>>), do: c in [?), ?], ?}]

  def bracket?(c) when is_empty(c), do: false
  def bracket?(<<c>>), do: c in [?[, ?]]

  def parenthesis?(c) when is_empty(c), do: false
  def parenthesis?(<<c>>), do: c in [?(, ?)]

  def brace?(c) when is_empty(c), do: false
  def brace?(<<c>>), do: c in [?{, ?}]

  def open_group?(c) when is_empty(c), do: false
  def open_group?(<<c>>), do: c in [?(, ?[, ?{]

  def bracket_type(char) do
    cond do
      parenthesis?(char) -> :parenthesis
      bracket?(char) -> :bracket
      brace?(char) -> :brace
      true -> :unknown
    end
  end

  defp process_last_child({buffer, token}) do
    last_token = Token.last_child(token)

    cond do
      not is_nil(last_token) and last_token.type == :group_close and
          last_token.category == token.category ->
        {buffer, Token.skip_last_child(token)}

      true ->
        {buffer,
         %Token{token | error: Error.new("Unmatching bracket for group #{token.category}")}}
    end
  end

  defp process_children(buffer, %Token{category: :brace} = token) do
    Parser.parse_buffer(Js.parsers(), buffer, token)
  end

  defp process_children(buffer, %Token{category: :bracket} = token) do
    Parser.parse_buffer(bracket_parser(), buffer, token)
  end

  defp process_children(buffer, %Token{category: :parenthesis} = token) do
    Parser.parse_buffer(bracket_parser(), buffer, token)
  end

  def get_group(buffer, enforced_category \\ nil) do
    char = Buffer.get_char(buffer)
    category = bracket_type(char)

    cond do
      not open_group?(char) and not is_nil(enforced_category) and category != enforced_category ->
        position = Buffer.position(buffer)
        new_buffer = Buffer.consume_char(buffer)

        token =
          Token.new(
            :group,
            interval: Buffer.interval(buffer, new_buffer),
            error: Error.new("Unexpected token #{char} at #{position}")
          )

        {new_buffer, token}

      open_group?(char) ->
        token =
          Token.new(
            :group,
            category: category
          )

        {new_buffer, new_token} =
          process_children(Buffer.consume_char(buffer), token)
          |> process_last_child()

        {new_buffer, %Token{new_token | interval: Buffer.interval(buffer, new_buffer)}}

      true ->
        :nomatch
    end
  end
end

defmodule Origami.Parser.Js.OpenGroup do
  @moduledoc false

  import Origami.Parser.Js.Group

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Token}

  @behaviour Parser

  @impl Parser
  def consume(buffer, token) do
    case get_group(buffer) do
      {buffer_out, children} ->
        {:cont, buffer_out, Token.concat(token, children)}

      _ ->
        :nomatch
    end
  end
end

defmodule Origami.Parser.Js.CloseGroup do
  @moduledoc false

  import Origami.Parser.Js.Group

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Token}

  @behaviour Parser

  @impl Parser
  def consume(buffer, tree) do
    case buffer
         |> Buffer.get_char()
         |> close_group?() do
      true ->
        {char, new_buffer} = Buffer.next_char(buffer)

        group_token =
          Token.new(
            :group_close,
            interval: Buffer.interval(buffer, new_buffer),
            category: bracket_type(char)
          )

        {
          :halt,
          new_buffer,
          Token.concat(tree, group_token)
        }

      _ ->
        :nomatch
    end
  end
end

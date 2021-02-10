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

  defp process_last_child({buffer, token}, start_interval) do
    last_token = Token.last_child(token)

    cond do
      not is_nil(last_token) and last_token.type == :group_close and
          last_token.data.category == token.data.category ->
        {buffer, Token.skip_last_child(token)}

      true ->
        error = Error.new("Unmatched group #{token.data.category}", interval: start_interval)
        {buffer, token |> Token.put(:error, error)}
    end
  end

  defp process_children(buffer, %Token{data: %{category: :brace}} = token) do
    Parser.parse_buffer(buffer, token, Js.parsers())
  end

  defp process_children(buffer, %Token{data: %{category: :bracket}} = token) do
    Parser.parse_buffer(buffer, token, bracket_parser())
  end

  defp process_children(buffer, %Token{data: %{category: :parenthesis}} = token) do
    Parser.parse_buffer(buffer, token, bracket_parser())
  end

  def get_group(buffer, enforced_category \\ nil) do
    {char, char_buffer} = Buffer.get_char(buffer)
    category = bracket_type(char)

    cond do
      open_group?(char) && (is_nil(enforced_category) || category == enforced_category) ->
        token =
          Token.new(
            :group,
            data: %{
              category: category
            }
          )

        {new_buffer, new_token} =
          process_children(char_buffer, token)
          |> process_last_child(Buffer.interval(buffer, char_buffer))

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
  alias Origami.Parser.{Buffer, Error, Token}

  @behaviour Parser

  @impl Parser
  def consume(buffer, tree) do
    {char, new_buffer} = Buffer.get_char(buffer)

    case close_group?(char) do
      true ->
        interval = Buffer.interval(buffer, new_buffer)

        token =
          Token.new(
            :group_close,
            interval: interval,
            data: %{
              category: bracket_type(char)
            }
          )

        case tree do
          %Token{type: :root} ->
            error = Error.new("Unmatched group #{token.data.category}", interval: interval)

            {
              :cont,
              new_buffer,
              token |> Token.put(:error, error)
            }

          _ ->
            {
              :halt,
              new_buffer,
              Token.concat(tree, token)
            }
        end

      _ ->
        :nomatch
    end
  end
end

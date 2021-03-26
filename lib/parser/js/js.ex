defmodule Origami.Parser.Js do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Syntax, Token}

  @behaviour Syntax

  @spec glued?(list(Token.t())) :: bool
  def glued?([]), do: false

  def glued?([_ | []]), do: false

  def glued?([
        %Token{interval: {_, _, stop_line, stop_col}}
        | [%Token{interval: {start_line, start_col, _, _}} | _]
      ]) do
    stop_line == start_line && stop_col + 1 == start_col
  end

  @spec same_line?(list(Token.t())) :: bool
  def same_line?([]), do: false

  def same_line?([_ | []]), do: false

  def same_line?([
        %Token{interval: {_, _, stop_line, _}}
        | [%Token{interval: {start_line, _, _, _}} | _]
      ]) do
    stop_line == start_line
  end

  def end_line?([]), do: true

  def end_line?([_ | []]), do: true

  def end_line?([%Token{type: :punctuation, data: %{category: :semicolon}} | []]), do: true

  def end_line?([
        %Token{interval: {_, _, stop_line, _}} | [%Token{interval: {start_line, _, _, _}} | _]
      ]) do
    stop_line + 1 == start_line
  end

  def end_line?(_), do: false

  def rearrange_token(token), do: Parser.rearrange_token(token, rearrangers())

  def rearrange_tokens(tokens), do: Parser.rearrange_tokens(tokens, rearrangers())

  def check_token(token), do: Parser.check_token(token, guards())

  def check_tokens(tokens), do: Parser.check_tokens(tokens, guards())

  @impl Syntax
  def rearrangers do
    [
      Origami.Parser.Js.Root,
      Origami.Parser.Js.Number,
      Origami.Parser.Js.Function,
      Origami.Parser.Js.Expression,
      Origami.Parser.Js.Declaration,
      Origami.Parser.Js.Punctuation
    ]
  end

  @impl Syntax
  def parsers do
    [
      Origami.Parser.Js.Space,
      Origami.Parser.Js.Punctuation,
      Origami.Parser.Js.Comment,
      Origami.Parser.Js.CommentBlock,
      Origami.Parser.Js.Identifier,
      Origami.Parser.Js.Number,
      Origami.Parser.Js.Function,
      Origami.Parser.Js.Keyword,
      Origami.Parser.Js.OpenGroup,
      Origami.Parser.Js.CloseGroup,
      Origami.Parser.Js.String,
      Origami.Parser.Js.Operator,
      Origami.Parser.Js.StoreVar,
      Origami.Parser.Js.Unknown
    ]
  end

  @impl Syntax
  def guards do
    [
      Origami.Parser.Js.Root,
      Origami.Parser.Js.Expression
    ]
  end
end

defmodule Origami.Parser.Js.Root do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Error, Interval, Js, Token}

  @behaviour Parser

  @impl Parser
  def rearrange([%Token{type: :root, data: %{children: children}} = root_token]) do
    case children do
      [] ->
        [root_token]

      [first_child | []] ->
        [
          root_token
          |> Token.put(:interval, first_child.interval)
          |> Token.put(:children, Js.rearrange_tokens(children))
        ]

      [first_child | _] ->
        last_child = Token.last_child(root_token)

        [
          root_token
          |> Token.put(:interval, Interval.merge(first_child.interval, last_child.interval))
          |> Token.put(:children, Js.rearrange_tokens(children))
        ]
    end
  end

  @impl Parser
  def rearrange([token | next_tokens] = tokens) do
    case Token.get(token, :children) do
      nil ->
        tokens

      children ->
        [
          Token.put(token, :children, Js.rearrange_tokens(children))
          | next_tokens
        ]
    end
  end

  @impl Parser
  def rearrange(tokens), do: tokens

  @impl Parser
  def check(%Token{interval: interval} = token) do
    errors =
      case Token.get(token, :error) do
        nil ->
          []

        error ->
          [%Error{error | interval: interval}]
      end

    case Token.get(token, :children) do
      nil ->
        errors

      children ->
        errors ++ Js.check_tokens(children)
    end
  end
end

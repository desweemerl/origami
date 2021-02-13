defmodule Origami.Parser.Js.Function do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Error, Token, Js}
  alias Origami.Parser.Js.{Group, Space, Identifier}

  @behaviour Parser

  @impl Parser
  def consume(buffer, token) do
    cond do
      Buffer.check_chars(buffer, "function") ->
        parse_function(buffer, token)

      true ->
        :nomatch
    end
  end

  defp generate_function_token(buffer) do
    {next_buffer, name} =
      buffer
      |> Buffer.consume_chars(8)
      |> Buffer.consume_chars(fn char -> Space.space?(char) end)
      |> Identifier.get_identifier()

    token = Token.new(:function, name: name)

    {next_buffer, token}
  end

  defp generate_arguments({buffer, token}) do
    case buffer
         |> Buffer.consume_chars(fn char -> Space.space?(char) end)
         |> Group.get_group(:parenthesis) do
      :nomatch ->
        error = Error.new("Missing arguments", interval: token.interval)
        {buffer, token |> Token.put(:error, error)}

      {new_buffer, %Token{data: %{error: error}}} ->
        {new_buffer, token |> Token.put(:error, error)}

      {new_buffer, token_arguments} ->
        case Token.get(token_arguments, :children, []) |> parse_arguments() do
          {:error, error} ->
            {new_buffer, Token.put(token, :error, error)}

          arguments ->
            {new_buffer, Token.put(token, :arguments, arguments)}
        end
    end
  end

  defp generate_body({buffer, %Token{data: %{error: _}} = token}) do
    {buffer, token}
  end

  defp generate_body({buffer, token}) do
    case buffer
         |> Buffer.consume_chars(fn char -> Space.space?(char) end)
         |> Group.get_group(:brace) do
      :nomatch ->
        error = Error.new("Unexpected token", interval: token.interval)
        {buffer, token |> Token.put(:error, error)}

      {new_buffer, %Token{data: %{error: error}}} ->
        {new_buffer, token |> Token.put(:error, error)}

      {new_buffer, token_body} ->
        children = Token.get(token_body, :children, []) |> Js.rearrange_tokens()
        {new_buffer, token |> Token.put(:body, children)}
    end
  end

  defp parse_arguments(tokens, arguments \\ []) do
    case tokens do
      [] ->
        arguments

      [%Token{type: :identifier} = argument | tail] ->
        case tail do
          [] ->
            arguments ++ [argument]

          [%Token{type: :punctuation, data: %{category: :comma}} | next_tokens] ->
            parse_arguments(next_tokens, arguments ++ [argument])

          [head | _] ->
            {:error, Error.new("unexpected token", interval: head.interval)}
        end

      [head | _] ->
        {:error, Error.new("unexpected token", interval: head.interval)}
    end
  end

  defp set_interval({buffer, token}, previous_buffer) do
    {buffer, %Token{token | interval: Buffer.interval(previous_buffer, buffer)}}
  end

  defp parse_function(buffer, token) do
    {new_buffer, new_token} =
      buffer
      |> generate_function_token()
      |> generate_arguments()
      |> generate_body()
      |> set_interval(buffer)

    {
      :cont,
      new_buffer,
      Token.concat(token, new_token)
    }
  end

  @impl Parser
  def rearrange([%Token{type: :function, data: %{body: body}} = head | tail]) do
    [
      Token.put(head, :body, Js.rearrange_tokens(body))
      | tail
    ]
  end

  @impl Parser
  def rearrange(tokens), do: tokens
end

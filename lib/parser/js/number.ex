defmodule Origami.Parser.Js.Number do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Error, Js, Token}

  use Bitwise, only_operators: true

  @none 0b00000000
  @negative 0b00000001
  @integer 0b00000010
  @float 0b00000100
  @hexadecimal 0b00001000
  @binary 0b00010000

  @behaviour Parser

  defguard is_char_digit(char_code) when char_code in ?0..?9

  defguard is_char_hex(char_code)
           when char_code in ?0..?9 or char_code in ?a..?f or char_code in ?A..?F

  defguard is_char_binary(char_code) when char_code in ?0..?1

  defp to_category(type) when (type &&& @hexadecimal) != 0 and (type &&& @negative) != 0 do
    :neg_hexadecimal
  end

  defp to_category(type) when (type &&& @hexadecimal) != 0, do: :hexadecimal

  defp to_category(type) when (type &&& @binary) != 0 and (type &&& @negative) != 0 do
    :neg_binary
  end

  defp to_category(type) when (type &&& @binary) != 0, do: :binary
  defp to_category(type) when (type &&& @float) != 0 and (type &&& @negative) != 0, do: :neg_float
  defp to_category(type) when (type &&& @float) != 0, do: :float

  defp to_category(type) when (type &&& @integer) != 0 and (type &&& @negative) != 0 do
    :neg_integer
  end

  defp to_category(type) when (type &&& @integer) != 0, do: :integer
  defp to_category(_), do: :unknown

  defp generate_error(char, buffer, number, type) do
    {new_buffer, new_number} =
      case Buffer.chars_until(buffer, " ", scope_line: true) do
        :nomatch ->
          {chars, nomatch_buffer} = Buffer.get_chars(buffer, -1)
          {nomatch_buffer, number <> chars}

        {chars, new_buffer} ->
          {new_buffer, number <> chars}
      end

    {
      new_buffer,
      new_number,
      to_category(type),
      Error.new("Unexpected token \"#{char}\"")
    }
  end

  defp process_char(char_code, type, number, _, new_buffer)
       when (is_char_digit(char_code) and ((type &&& @integer) != 0 or (type &&& @float) != 0)) or
              (is_char_hex(char_code) and (type &&& @hexadecimal) != 0) or
              (is_char_binary(char_code) and (type &&& @binary) != 0) do
    get_number(new_buffer, number <> <<char_code>>, type)
  end

  defp process_char(char_code, type, number, _, new_buffer)
       when is_char_digit(char_code) and type in [@none, @negative] do
    get_number(new_buffer, number <> <<char_code>>, type ||| @integer)
  end

  defp process_char(?\., type, number, buffer, new_buffer) do
    if (type &&& @float) != 0 do
      generate_error(".", buffer, number, type)
    else
      get_number(new_buffer, number <> ".", type ||| @float)
    end
  end

  defp process_char(?\-, type, number, _, new_buffer)
       when type == @none do
    get_number(new_buffer, number <> "-", type ||| @negative)
  end

  defp process_char(?\s, type, number, _, new_buffer)
       when type == @negative do
    get_number(new_buffer, number, type)
  end

  defp process_char(char, type, number, _, new_buffer)
       when char in [?x, ?X] and number in ["0", "-0"] do
    get_number(new_buffer, number <> <<char>>, type ||| @hexadecimal)
  end

  defp process_char(char, type, number, _, new_buffer)
       when char in [?b, ?B] and number in ["0", "-0"] do
    get_number(new_buffer, number <> <<char>>, type ||| @binary)
  end

  defp process_char(_, type, number, buffer, _) do
    {
      buffer,
      number,
      to_category(type),
      nil
    }
  end

  defp get_number(buffer, number, type \\ 0) do
    {char, new_buffer} = Buffer.get_char(buffer)

    if is_nil(char) || char == "" do
      process_char(0, type, number, buffer, new_buffer)
    else
      <<char_code>> = char
      process_char(char_code, type, number, buffer, new_buffer)
    end
  end

  def get_number(buffer), do: get_number(buffer, "")

  @impl Parser
  def consume(buffer, token) do
    case get_number(buffer) do
      {_, "", _, _} ->
        :nomatch

      {new_buffer, number, category, error} ->
        data = [
          value: number,
          category: category
        ]

        new_token =
          Token.new(
            :number,
            Buffer.interval(buffer, new_buffer),
            (is_nil(error) && data) || data ++ [error: error]
          )

        {
          :cont,
          new_buffer,
          Token.concat(token, new_token)
        }
    end
  end

  @impl Parser
  def rearrange([%Token{type: :number} | [%Token{type: type} | _]] = tokens)
      when type in [:operator, :punctuation] do
    tokens
  end

  @impl Parser
  def rearrange([%Token{type: :number} = token | next_tokens] = tokens) do
    if Js.glued?(tokens) do
      [next_token | remaining_tokens] = next_tokens

      [
        token
        | [
            Token.put(next_token, :error, Error.new("Unexpected token"))
            | remaining_tokens
          ]
      ]
    else
      tokens
    end
  end

  @impl Parser
  def rearrange(tokens), do: tokens
end

defmodule Origami.Parser.Js.Number do
  @moduledoc false

  alias Origami.Parser
  alias Origami.Parser.{Buffer, Error, Token}

  use Bitwise, only_operators: true

  @none 0b00000000
  @negative 0b00000001
  @integer 0b00000010
  @float 0b00000100
  @hexadecimal 0b00001000
  @binary 0b00010000

  @behaviour Parser

  defguard is_empty(value) when is_nil(value) or value == ""

  @spec digit?(any) :: boolean
  def digit?(c) when is_empty(c), do: false
  def digit?(<<c>>), do: c in ?0..?9

  @spec hexadecimal?(any) :: boolean
  def hexadecimal?(c) when is_empty(c), do: false
  def hexadecimal?(<<c>>), do: digit?(<<c>>) || c in ?a..?f || c in ?A..?F

  @spec binary?(any) :: boolean
  def binary?(c) when is_empty(c), do: false
  def binary?(c), do: c in ["0", "1"]

  defp to_category(type) do
    cond do
      (type &&& @hexadecimal) != 0 && (type &&& @negative) != 0 -> :neg_hexadecimal
      (type &&& @hexadecimal) != 0 -> :hexadecimal
      (type &&& @binary) != 0 && (type &&& @negative) != 0 -> :neg_binary
      (type &&& @binary) != 0 -> :binary
      (type &&& @float) != 0 && (type &&& @negative) != 0 -> :neg_float
      (type &&& @float) != 0 -> :float
      (type &&& @integer) != 0 && (type &&& @negative) != 0 -> :neg_integer
      (type &&& @integer) != 0 -> :integer
      true -> :unknown
    end
  end

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

  defp get_number(buffer, number, type \\ 0) do
    {char, new_buffer} = Buffer.get_char(buffer)

    cond do
      digit?(char) && ((type &&& @integer) != 0 || (type &&& @float) != 0) ->
        get_number(new_buffer, number <> char, type)

      hexadecimal?(char) && (type &&& @hexadecimal) != 0 ->
        get_number(new_buffer, number <> char, type)

      binary?(char) && (type &&& @binary) != 0 ->
        get_number(new_buffer, number <> char, type)

      digit?(char) && type in [@none, @negative] ->
        get_number(new_buffer, number <> char, type ||| @integer)

      char == "." ->
        cond do
          (type &&& @float) != 0 ->
            generate_error(char, buffer, number, type)

          true ->
            get_number(new_buffer, number <> char, type ||| @float)
        end

      char == "-" && type == @none ->
        get_number(new_buffer, number <> char, @negative)

      char == " " && type == @negative ->
        get_number(new_buffer, number, type)

      char in ["x", "X"] && number in ["0", "-0"] ->
        get_number(new_buffer, number <> char, type ||| @hexadecimal)

      char in ["b", "B"] && number in ["0", "-0"] ->
        get_number(new_buffer, number <> char, type ||| @binary)

      !is_nil(char) && char not in [" ", ""] && number <> "" ->
        generate_error(char, buffer, number, type)

      true ->
        {
          buffer,
          number,
          to_category(type),
          nil
        }
    end
  end

  def get_number(buffer), do: get_number(buffer, "")

  @impl Parser
  def consume(buffer, token) do
    case get_number(buffer) do
      {_, "", @none, nil} ->
        :nomatch

      {new_buffer, number, category, error} ->
        new_token =
          Token.new(
            :number,
            content: number,
            error: error,
            category: category,
            interval: Buffer.interval(buffer, new_buffer)
          )

        {
          :cont,
          new_buffer,
          Token.concat(token, new_token)
        }
    end
  end
end

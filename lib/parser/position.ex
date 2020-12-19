defmodule Origami.Parser.Position do
  @moduledoc false

  alias __MODULE__
  alias Origami.Parser.Buffer

  @enforce_keys [:line, :col]
  defstruct line: 0,
            col: 0

  @type t() :: %Position{
          line: pos_integer,
          col: pos_integer
        }

  @spec new(pos_integer, pos_integer) :: Position.t()
  def new(line, col), do: %Position{line: line, col: col}

  @spec add_length(Position.t(), String.t() | integer) :: Position.t()
  def add_length(position, 0), do: position

  def add_length(position, length) when is_integer(length) do
    %Position{position | col: position.col + length - 1}
  end

  def add_length(position, content) when is_binary(content) do
    add_length(position, String.length(content))
  end
end

defimpl String.Chars, for: Origami.Parser.Position do
  def to_string(term) do
    "#{term.line + 1}:#{term.col + 1}"
  end
end

defmodule Origami.Parser.Interval do
  @moduledoc false

  alias __MODULE__
  alias Origami.Parser.Position

  @enforce_keys [:start, :stop]
  defstruct [:start, :stop]

  @type t() :: %Interval{
          start: Position.t(),
          stop: Position.t()
        }

  @spec new(Position.t(), Position.t()) :: Interval.t()
  def new(start, stop), do: %Interval{start: start, stop: stop}

  @spec new(pos_integer, pos_integer, pos_integer, pos_integer) :: Interval.t()
  def new(line_start, col_start, line_stop, col_stop) do
    Interval.new(
      Position.new(line_start, col_start),
      Position.new(line_stop, col_stop)
    )
  end

  @spec merge(Interval.t(), Interval.t()) :: Interval.t()
  def merge(interval1, interval2) do
    %Interval{
      start: interval1.start,
      stop: interval2.stop
    }
  end
end

defimpl String.Chars, for: Origami.Parser.Interval do
  def to_string(term) do
    "start at #{term.start} stop at #{term.stop}"
  end
end

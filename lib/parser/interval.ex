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
end

defimpl String.Chars, for: Origami.Parser.Interval do
  def to_string(term) do
    "start at #{term.start} stop at #{term.stop}"
  end
end

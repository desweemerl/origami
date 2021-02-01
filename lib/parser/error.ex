defmodule Origami.Parser.Error do
  @moduledoc false

  alias __MODULE__
  alias Origami.Parser.Interval

  @enforce_keys [:message, :interval]
  defstruct [
    :message,
    :interval
  ]

  @type t() :: %Error{
          message: String.t(),
          interval: Interval.t()
        }

  def new(message, config \\ []) do
    %Error{
      message: message,
      interval: Keyword.get(config, :interval)
    }
  end
end

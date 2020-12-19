defmodule Origami.Parser.Error do
  @moduledoc false

  alias __MODULE__
  alias Origami.Parser.Position

  @enforce_keys [:message, :position]
  defstruct [
    :message,
    :position
  ]

  @type t() :: %Error{
          message: String.t(),
          position: Position.t()
        }

  def new(message, config \\ []) do
    %Error{
      message: message,
      position: Keyword.get(config, :position)
    }
  end
end

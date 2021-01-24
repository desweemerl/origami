defmodule Origami.Parser.Js.Expression do
  @moduledoc false

  alias Origami.Parser

  @behaviour Parser

  @impl Parser
  def rearrange(tokens), do: tokens
end

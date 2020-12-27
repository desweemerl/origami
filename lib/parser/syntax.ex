defmodule Origami.Parser.Syntax do
  @moduledoc false

  @callback parsers() :: list(module())

  @callback rearrangers() :: list(module())
end

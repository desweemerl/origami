defmodule Origami.Processor do
  alias Origami.Parser
  alias Origami.Parser.{BufferText, Js}
  alias Origami.Document

  # @var1 = value1 translated as store.set(value1, ['var1'])
  def process_node(file, {"script", _attributes, children_nodes}, document) do
    Enum.at(children_nodes, 0)
    |> Parser.parse(parsers: Js.parsers())
  end

  def process_node(file, {node, attributes, children_nodes}, document) do
    document
  end
end

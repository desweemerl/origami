defmodule Origami.Parser.Token do
  alias __MODULE__

  alias Origami.Parser.{Error, Interval}

  @type t :: %Token{
          type: atom,
          interval: Interval.t(),
          children: list,
          data: map()
        }

  @enforce_keys [:type]
  defstruct [
    :type,
    :interval,
    :children,
    :data
  ]

  def new(type, config \\ []) do
    %Token{
      type: type,
      interval: Keyword.get(config, :interval),
      children: Keyword.get(config, :children, []),
      data: Keyword.get(config, :data, %{})
    }
  end

  def concat(%Token{children: children} = token, child_token) do
    %Token{token | children: children ++ [child_token]}
  end

  def put(%Token{data: data} = token, key, value) do
    %Token{token | data: Map.put(data, key, value)}
  end

  def last_child(token, default \\ nil)

  def last_child(%Token{children: []}, default), do: default

  def last_child(%Token{children: children}, _) do
    [last | _] = Enum.reverse(children)
    last
  end

  def skip_last_child(%Token{children: []} = token), do: token

  def skip_last_child(%Token{children: children} = token) do
    [_ | tail] = Enum.reverse(children)

    %Token{token | children: Enum.reverse(tail)}
  end
end

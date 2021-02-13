defmodule Origami.Parser.Token do
  alias __MODULE__
  alias Origami.Parser.Interval

  @type t :: %Token{
          type: atom,
          interval: Interval.t(),
          data: map()
        }

  @enforce_keys [:type]
  defstruct [
    :type,
    interval: nil,
    data: %{}
  ]

  def new(type) do
    %Token{type: type}
  end

  def new(type, {_, _, _, _} = interval) do
    new(type, interval, [])
  end

  def new(type, config) when is_list(config) do
    new(type, nil, config)
  end

  def new(type, interval, config) when is_tuple(interval) or is_nil(interval) do
    data = Enum.into(config, %{})

    %Token{
      type: type,
      interval: interval,
      data: data
    }
  end

  def put(%Token{data: data} = token, key, value) do
    %Token{token | data: Map.put(data, key, value)}
  end

  def get(%Token{data: data}, key, default \\ nil) do
    Map.get(data, key, default)
  end

  def concat(token, child_token) do
    children = get(token, :children, [])
    put(token, :children, children ++ [child_token])
  end

  def last_child(token, default \\ nil) do
    case get(token, :children, []) do
      [] ->
        default

      children ->
        [last | _] = Enum.reverse(children)
        last
    end
  end

  def skip_last_child(token) do
    case get(token, :children, []) do
      [] ->
        token

      children ->
        [_ | tail] = Enum.reverse(children)
        put(token, :children, Enum.reverse(tail))
    end
  end
end

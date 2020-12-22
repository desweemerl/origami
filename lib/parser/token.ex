defmodule Origami.Parser.Token do
  alias __MODULE__

  alias Origami.Parser.{Error, Interval}

  @type t :: %Token{
          type: atom,
          name: String.t(),
          category: atom,
          arguments: list,
          content: String.t(),
          interval: Interval.t(),
          children: list,
          error: Error.t()
        }

  @enforce_keys [:type]
  defstruct [
    :type,
    :name,
    :category,
    :arguments,
    :content,
    :interval,
    :children,
    :error
  ]

  def new(type, config \\ []) do
    %Token{
      type: type,
      name: Keyword.get(config, :name, ""),
      category: Keyword.get(config, :category),
      arguments: Keyword.get(config, :arguments, []),
      content: Keyword.get(config, :content, ""),
      interval: Keyword.get(config, :interval),
      children: Keyword.get(config, :children, []),
      error: Keyword.get(config, :error)
    }
  end

  def concat(%Token{children: children} = token, child_token) do
    %Token{token | children: children ++ [child_token]}
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

  def merge_content(%Token{children: []} = token, child_token) do
    %Token{token | children: [child_token]}
  end

  def merge_content(
        %Token{children: children} = token,
        child_token
      ) do
    cond do
      ([last | tail] = Enum.reverse(children)) and last.type == child_token.type ->
        new_content = last.content <> child_token.content
        new_children = Enum.reverse([%Token{last | content: new_content} | tail])
        %Token{token | children: new_children}

      true ->
        concat(token, child_token)
    end
  end
end

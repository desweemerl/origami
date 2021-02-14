defmodule Origami.InteractionChannel do
  @moduledoc false

  use Phoenix.Channel

  def join("origami:interaction", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("ping", attrs, socket) do
    {:reply, {:ok, attrs}, socket}
  end
end

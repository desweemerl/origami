defmodule Origami.InteractionChannel do
  use Phoenix.Channel

  def join("origami:interaction", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("ping", attrs, socket) do
    {:reply, {:ok, attrs}, socket}
  end
end

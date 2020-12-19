defmodule Origami.Socket do
  use Phoenix.Socket

  channel("origami:interaction", Origami.InteractionChannel)

  def connect(params, socket, _connect_info) do
    {:ok, assign(socket, :user_id, params["user_id"])}
  end

  def id(socket), do: "interaction:#{socket.assigns.user_id}}"
end

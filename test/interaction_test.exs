defmodule Origami.InteractionChannelTest do
  use Origami.ChannelCase

  setup do
    {:ok, _, socket} =
      Origami.Socket
      |> socket("user_id", %{some: :assign})
      |> subscribe_and_join(Origami.InteractionChannel, "origami:interaction")

    %{socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply(ref, :ok, %{"hello" => "there"})
  end
end

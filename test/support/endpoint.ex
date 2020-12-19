defmodule Origami.Endpoint do
  use Phoenix.Endpoint, otp_app: :origami

  socket("/origami", Origami.Socket, websocket: true, longpoll: false)
end

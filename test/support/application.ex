defmodule Origami.ApplicationTest do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      {Phoenix.PubSub, name: Origami.PubSub},
      Origami.Endpoint
    ]

    opts = [
      strategy: :one_for_one,
      name: Origami.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end

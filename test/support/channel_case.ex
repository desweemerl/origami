defmodule Origami.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest

      @endpoint Origami.Endpoint
    end
  end
end

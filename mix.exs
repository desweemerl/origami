defmodule Origami.MixProject do
  use Mix.Project

  def project do
    [
      app: :origami,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      dialyzer: [
        plt_core_path: "priv/plts",
        plt_add_apps: [:mix, :ex_unit]
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      mod: mod(Mix.env()),
      extra_applications: [:logger]
    ]
  end

  defp mod(:test), do: {Origami.ApplicationTest, []}
  defp mod(_), do: []

  defp deps do
    [
      {:phoenix, "~> 1.5.6"},
      {:phoenix_pubsub, "~> 2.0.0"},
      {:jason, "~> 1.2.2"},
      {:floki, "~> 0.29.0"},
      {:file_system, "~> 0.2.9"},
      {:excoveralls, "~> 0.13"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end
end

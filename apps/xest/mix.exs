defmodule Xest.MixProject do
  use Mix.Project

  def project do
    [
      app: :xest,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Xest.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:dev), do: ["lib", "test/support"]  # to be able to interactively use test/support
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},

      {:phoenix_pubsub, "~> 2.0"},

      {:tesla, "~> 1.4.0"},
      # optional, but recommended adapter
      {:hackney, "~> 1.16.0"},
      # optional, required by JSON middleware
      {:jason, ">= 1.0.0"},
      {:fuse, "~> 2.4"},

#      {:assert_value, ">= 0.0.0", only: [:dev, :test]}, # TODO : recording instead ?
      {:flow_assertions, "~> 0.6", only: :test},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end

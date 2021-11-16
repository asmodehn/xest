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
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      # see https://hexdocs.pm/dialyxir/readme.html for options
      dialyzer: [
        plt_add_deps: :apps_direct
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      # if you want to use espec,
      # test_coverage: [tool: ExCoveralls, test_task: "espec"]
      # The main page in the docs
      docs: [main: "Xest", extras: ["README.md"]]
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
  # to be able to interactively use test/support
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Tooling
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.10", only: [:dev, :test]},
      {:doctor, "~> 0.17.0", only: :dev},

      # phoenix communication
      {:phoenix_pubsub, "~> 2.0"},

      # Time manipulation
      {:timex, "~> 3.0"},

      # Functional patterns
      #      {:witchcraft, "~> 1.0"},
      # necessary to work with elixir 1.12. waiting for next release...
      {:witchcraft, git: "git://github.com/witchcrafters/witchcraft.git", override: true},
      {:algae, "~> 1.3"},

      # Test libs
      #      {:assert_value, ">= 0.0.0", only: [:dev, :test]}, # TODO : recording instead ?
      {:flow_assertions, "~> 0.6", only: [:dev, :test]},
      {:hammox, "~> 0.4", only: [:test, :dev]},

      # Docs
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
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

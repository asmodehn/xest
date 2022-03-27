defmodule XestBinance.MixProject do
  use Mix.Project

  def project do
    [
      app: :xest_binance,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      # see https://hexdocs.pm/dialyxir/readme.html for options
      dialyzer: [
        plt_add_deps: :apps_direct
      ],
      test_paths: ["tests/unit", "tests/integration"],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        vcr: :test,
        "vcr.delete": :test,
        "vcr.check": :test,
        "vcr.show": :test
      ],
      # if you want to use espec,
      # test_coverage: [tool: ExCoveralls, test_task: "espec"]
      # The main page in the docs
      docs: [main: "XestBinance", extras: ["README.md"]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {XestBinance.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  # to be able to interactively use test/support
  defp elixirc_paths(:dev), do: ["lib", "tests/unit/support"]
  defp elixirc_paths(:test), do: ["lib", "tests/unit/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:xest, in_umbrella: true},

      # Binance client !
      #  {:binance, "~> 1.0.1"},
      {:binance, git: "git@github.com:asmodehn/binance.ex.git", branch: "add_my_trades"},
      #              {:binance, path: "../../../binance.ex"},

      # Recording API Responses in tests
      {:exvcr, "~> 0.11", only: [:dev, :test]},

      # For integration tests with an actual HTTP server
      {:bypass, "~> 2.1", only: [:dev, :test]},

      # To generate data in tests
      {:stream_data, "~> 0.5", only: [:dev, :test]},

      # Time manipulation
      {:timex, "~> 3.0"},

      # Cache
      {:nebulex, "~> 2.1"},
      #    {:shards, "~> 1.0"},      #=> When using :shards as backend on high workloads
      # => When using Caching Annotations
      {:decorator, "~> 1.3"},
      # => When using the Telemetry events (Nebulex stats)
      {:telemetry, "~> 0.4"},

      # Runtime configuration
      {:vapor, "~> 0.10"},

      # Docs
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"],
      test: ["test"]
    ]
  end
end

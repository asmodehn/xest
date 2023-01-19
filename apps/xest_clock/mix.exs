defmodule XestClock.MixProject do
  use Mix.Project

  def project do
    [
      app: :xest_clock,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: true],
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "XestClock",
      source_url: "https://github.com/asmodehn/xest",
      homepage_url: "https://github.com/asmodehn/xest",
      docs: [
        # The main page in the docs
        main: "XestClock",
        #        logo: "path/to/logo.png",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  # to be able to interactively use test/support
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Prod Dependencies
      {:interval, "~> 0.3.2"},

      # Dev libs
      {:gen_stage, "~> 1.0", only: [:test]},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      # TODO : use typecheck in dev and test, not prod.
      # might not help much with stream or processes, but will help detecting api / functional issues
      # along with simple property testing for code structure

      # Test libs
      {:hammox, "~> 0.4", only: [:test, :dev]},

      # Docs
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end

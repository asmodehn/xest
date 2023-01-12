defmodule XestCache.MixProject do
  use Mix.Project

  def project do
    [
      app: :xest_cache,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {XestCache.Application, []}
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
      {:xest_clock, in_umbrella: true},

      # Time manipulation
      {:timex, "~> 3.0"},
      {:nebulex, "~> 2.4"},
      # => For using Caching Annotations
      {:decorator, "~> 1.4"},
      # => For using the Telemetry events (Nebulex stats)
      {:telemetry, "~> 1.0"},

      # Dev libs
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},

      # WORKAROUND transitive dependency problem in umbrella...
      # TODO : report it...
      {:gen_stage, "~> 1.0", only: [:test]},

      # Docs
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end

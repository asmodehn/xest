defmodule Xest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: Xest.PubSub},

      # Starting main Binance Server
      {Xest.BinanceServer, name: Xest.BinanceServer},
      # Starting main Exchange Agent managing retrieved state
      {Xest.BinanceExchange, name: Xest.BinanceExchange}

      # TUI process
      # disabling since this messes up the input terminal...
      #      {Ratatouille.Runtime.Supervisor, runtime: [app: Xest.TUI]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Xest.Supervisor)
  end
end

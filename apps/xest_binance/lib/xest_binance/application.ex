defmodule XestBinance.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    config = Vapor.load!(XestBinance.Config)

    children = [
      # Cache for Adapter to avoid useless spamming of the exchange from this IP.
      {XestBinance.Adapter.Cache, []},

      # Starting Clock Agent
      {XestBinance.Clock, name: XestBinance.Clock},

      # Starting main Binance Server
      {XestBinance.Server, name: XestBinance.Server, endpoint: config.xest_binance.endpoint},

      # Starting authenticated Binance Server for user account
      {XestBinance.Auth,
       name: XestBinance.Auth,
       apikey: config.xest_binance.apikey,
       secret: config.xest_binance.secret,
       endpoint: config.xest_binance.endpoint},

      # Starting main Exchange Agent managing retrieved state
      {XestBinance.Exchange, name: XestBinance.Exchange},

      # Starting main Account Agent managing retrieved state
      {
        XestBinance.Account,
        # supports only one auth at a time.
        name: XestBinance.Account, auth_mod: XestBinance.Auth, auth_pid: XestBinance.Auth
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: XestBinance.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

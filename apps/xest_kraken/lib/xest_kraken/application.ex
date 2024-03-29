defmodule XestKraken.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    config = Vapor.load!(XestKraken.Config)

    children = [
      # Starts the adapter cache
      {XestKraken.Adapter.Cache, []},

      # Starting Clock Agent
      {XestKraken.Clock, name: XestKraken.Clock},

      # Starting authenticated Kraken Server for user account
      {XestKraken.Auth,
       name: XestKraken.Auth,
       apikey: config.xest_kraken.apikey,
       secret: config.xest_kraken.secret,
       endpoint: config.xest_kraken.endpoint},

      # Starting main Exchange Agent managing retrieved state
      {XestKraken.Exchange, name: XestKraken.Exchange},

      # Starting main Account Agent managing retrieved state
      {
        XestKraken.Account,
        # supports only one auth at a time.
        name: XestKraken.Account, auth_mod: XestKraken.Auth, auth_pid: XestKraken.Auth
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: XestKraken.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

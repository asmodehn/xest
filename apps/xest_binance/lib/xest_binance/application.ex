defmodule XestBinance.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starting main Binance Server
      {XestBinance.Server, name: XestBinance.Server},
      # Starting main Exchange Agent managing retrieved state
      {XestBinance.Exchange, name: XestBinance.Exchange}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: XestBinance.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

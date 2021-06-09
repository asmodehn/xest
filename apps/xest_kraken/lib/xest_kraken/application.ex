defmodule XestKraken.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts the adapter cache
      {XestKraken.Adapter.Cache, []},

      # Starting Clock Agent
      {XestKraken.Clock, name: XestKraken.Clock},

      # Starting main Exchange Agent managing retrieved state
      {XestKraken.Exchange, name: XestKraken.Exchange}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: XestKraken.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

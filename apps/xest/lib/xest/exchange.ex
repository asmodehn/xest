defmodule Xest.BinanceExchange do
  @moduledoc """
  An Agent attempting to maintain a consistent view (as state) of the exchange
  It holds the knowledge of this system regarding binance.
  """

  defstruct url: "http://api.binance.com",
            minimum_status_request_period_seconds: 60,
            server_time_request_period_seconds: 60,
            # these are the minimal amount of state necessary
            # to estimate current real world binance exchange status
            status: %{message: nil, code: nil},
            server_time_skew: nil

  alias Xest.Binance

  # careful to not get mixed up with core DateTime...
  @datetime Application.get_env(:xest, :datetime)

  # Note the agent should be unique
  use Agent
  # -> we can use the module name as a default to identify it

  def start_link(opts) do
    # starting the agent by passing the struct as initial value
    # Note : mocks should manually modify the initial struct if needed
    Agent.start_link(
      fn -> %Xest.BinanceExchange{} end,
      opts
    )
  end

  # redirection to actual or mock implementation depending on app env config
  def utc_now() do
    @datetime.utc_now()
  end

  # smart accessor
  def status(exchange) do
    case Agent.get(exchange, &Map.get(&1, :status)) do
      %{message: nil, code: _} -> retrieve_status(exchange)
      %{message: _, code: nil} -> retrieve_status(exchange)
      status -> status
    end
  end

  # internal functions to trigger REST request, kept internal for isolation purposes
  defp retrieve_status(exchange) do
    %{"msg" => msg, "status" => status} = Binance.system_status()

    :ok =
      Agent.update(exchange, fn state ->
        %{state | status: %{message: msg, code: status}}
      end)

    Agent.get(exchange, &Map.get(&1, :status))
  end

  #  defp retrieve_servertime(exchange) do
  #    %{"serverTime" => server_time} = Binance.time()
  #    :ok = Agent.update(exchange, fn state ->
  #      %{state | server_time_skew: utc_now() - server_time }
  #    end)
  #  end

  @doc """
  Access the state of the exchange agent.
  This encodes our knowledge of binance exchange
  """
  def state(exchange) do
    Agent.get(exchange, &Function.identity/1)
  end
end

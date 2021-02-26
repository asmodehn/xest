defmodule Xest.BinanceExchange do
  @moduledoc """
  An Agent attempting to maintain a consistent view (as state) of the exchange
  It holds the knowledge of this system regarding binance.
  """
  alias Xest.Models

  # TODO : move that to the binance client genserver...
  @default_minimum_request_period ~T[00:00:01]

  # these are the minimal amount of state necessary
  # to estimate current real world binance exchange status
  defstruct model: %Models.Exchange{},
            minimal_request_period: @default_minimum_request_period

  alias Xest.BinanceClient

  use Agent

  def start_link(opts, minimal_request_period \\ @default_minimum_request_period) do
    # starting the agent by passing the struct as initial value
    # - app can tune the minimal_request_period
    # - mocks should manually modify the initial struct if needed
    Agent.start_link(
      fn -> %{%Xest.BinanceExchange{} | minimal_request_period: minimal_request_period} end,
      opts
    )
  end

  def model(agent) do
    Agent.get(agent, fn state -> state.model end)
  end

  # TODO : these 2 should be the same...
  @doc """
  Access the state of the exchange agent.
  This encodes our knowledge of binance exchange
  """
  def state(exchange) do
    Agent.get(exchange, &Function.identity/1)
  end

  # lazy accessor
  def status(agent) do
    case Agent.get(agent, fn state -> state.model.status end) do
      %{message: nil, code: _} -> retrieve_status(agent)
      %{message: _, code: nil} -> retrieve_status(agent)
      status -> status
    end
  end

  # internal functions to trigger REST request, kept internal for isolation purposes
  defp retrieve_status(agent) do
    %{"msg" => msg, "status" => status} = BinanceClient.system_status()

    :ok =
      Agent.update(agent, fn state ->
        %{state | model: %Models.Exchange{status: %{message: msg, code: status}}}
      end)

    Agent.get(agent, &get_in(&1, [:model, :status]))
  end

  #  defp retrieve_servertime(exchange) do
  #    %{"serverTime" => server_time} = Binance.time()
  #    :ok = Agent.update(exchange, fn state ->
  #      %{state | server_time_skew: utc_now() - server_time }
  #    end)
  #  end
end

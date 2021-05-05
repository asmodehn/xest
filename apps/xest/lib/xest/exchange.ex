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
  @enforce_keys [:minimal_request_period, :shadow_clock]
  defstruct model: %Models.Exchange{},
            # pointing to the binance client pid
            client: nil,
            # TODO : maybe in model instead ?
            shadow_clock: nil,
            minimal_request_period: @default_minimum_request_period

  @typedoc "A exchange data structure, used as a local proxy for the actual exchange"
  @type t() :: %__MODULE__{
          model: Models.Exchange.t(),
          # TODO: Xest.Ports.BinanceClientBehaviour.t() | nil,
          client: any(),
          shadow_clock: Xest.ShadowClock.t() | nil,
          minimal_request_period: Time.t() | nil
        }

  alias Xest.BinanceClient

  use Agent

  def remote_clock(client) do
    BinanceClient.time!(client)["serverTime"]
    |> DateTime.from_unix!(:millisecond)
  end

  def start_link(opts, minimal_request_period \\ @default_minimum_request_period) do
    {client, opts} = Keyword.pop(opts, :client, {:via, Registry, Xest.BinanceClient.via_tuple()})
    {clock, opts} = Keyword.pop(opts, :clock, Xest.ShadowClock.new(remote_clock(client)))

    # starting the agent by passing the struct as initial value
    # - app can tune the minimal_request_period
    # - mocks should manually modify the initial struct if needed
    exchange_struct = %Xest.BinanceExchange{
      shadow_clock: clock,
      minimal_request_period: minimal_request_period,
      client: client
    }

    Agent.start_link(
      fn -> exchange_struct end,
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
    Agent.get_and_update(agent, fn state ->
      case state.model.status do
        status when is_nil(status.message) or is_nil(status.code) ->
          # TODO this should probably be in the API / some ACL...
          {:ok, %{"msg" => msg, "status" => code}} = BinanceClient.system_status(state.client)
          status = %Models.ExchangeStatus{message: msg, code: code}

          {status,
           state
           |> Map.put(
             :model,
             state.model
             |> Models.Exchange.update(status: status)
           )}

        status ->
          {status, state}
          # TODO : add a case to check for timeout to request again the status
      end
    end)
  end

  def servertime(agent) do
    # TODO : have some refresh to avoid too big a time skew...
    clock =
      Agent.get_and_update(agent, fn state ->
        {state.shadow_clock, state.shadow_clock |> Xest.ShadowClock.update()}
      end)

    Xest.ShadowClock.now(clock)
  end
end

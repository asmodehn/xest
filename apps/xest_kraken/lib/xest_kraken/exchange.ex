defmodule XestKraken.Exchange do
  @moduledoc """
  An Agent attempting to maintain a consistent view (as state) of the exchange
  It holds the knowledge of this system regarding kraken.
  """
  alias XestKraken.Adapter

  @behaviour XestKraken.Exchange.Behaviour

  @default_minimum_request_period ~T[00:00:01]

  @public_client Adapter.Client.new(nil, nil)

  # these are the minimal amount of state necessary
  # to estimate current real world binance exchange status
  # , :shadow_clock]
  @enforce_keys [:minimal_request_period]
  defstruct status: nil,
            # a public client by default
            client: @public_client,
            shadow_clock: nil,
            servertime: nil,
            minimal_request_period: @default_minimum_request_period

  @typedoc "A exchange data structure, used as a local proxy for the actual exchange"
  @type t() :: %__MODULE__{
          status: Exchange.Status.t() | nil,
          client: XestKraken.Krakex.Client.t() | nil,
          shadow_clock: Xest.ShadowClock.t() | nil,
          servertime: Xest.Exchange.ServerTime.t() | nil,
          minimal_request_period: Time.t() | nil
        }

  defmodule Behaviour do
    @moduledoc """
    A behaviour to allow mocks when multiprocess tests are not desired.
    """

    @type status :: XestKraken.Exchange.Status.t()
    @type reason :: String.t()

    @type servertime :: Xest.ShadowClock.t()
    @type mockable_pid :: nil | pid()

    # | {:error, reason}
    @callback status(mockable_pid()) :: status

    # | {:error, reason}
    @callback servertime(mockable_pid()) :: servertime

    # TODO : by leveraging __using__ we could implement default function
    #                                   and their unsafe counterparts maybe ?
  end

  use Agent

  def start_link(opts, minimal_request_period \\ @default_minimum_request_period) do
    {client, opts} = Keyword.pop(opts, :client, @public_client)

    # REMINDER : we dont want to call external systems on startup.
    # Other processes need to align before this can safely happen in various environments.
    #    {clock, opts} =
    #      Keyword.pop(opts, :clock, Xest.ShadowClock.new(fn -> kraken_adapter().time!(client) end))

    # starting the agent by passing the struct as initial value
    # - app can tune the minimal_request_period
    # - mocks should manually modify the initial struct if needed
    exchange_struct = %XestKraken.Exchange{
      #      shadow_clock: clock,
      minimal_request_period: minimal_request_period,
      client: client
    }

    Agent.start_link(
      fn -> exchange_struct end,
      opts
    )
  end

  defp kraken_adapter do
    Application.get_env(:xest_kraken, :adapter)
  end

  @doc """
  Access the state of the exchange agent.
  This encodes our knowledge of binance exchange
  """
  def state(agent) do
    Agent.get(agent, &Function.identity/1)
  end

  # lazy accessor
  @impl true
  def status(agent) do
    Agent.get_and_update(agent, fn state ->
      case state.status do
        status when is_nil(status) ->
          {:ok, response} = kraken_adapter().system_status(state.client)

          status = XestKraken.Exchange.Status.new(response)

          {status,
           state
           |> Map.put(:status, status)}

        # TODO : add a case to check for timeout to request again the status

        status ->
          {status, state}
      end
    end)
  end

  @impl true
  def servertime(agent) do
    Agent.get_and_update(agent, fn state ->
      case state.servertime do
        nil ->
          st = XestKraken.Adapter.servertime()

          {st,
           state
           |> Map.put(
             :servertime,
             st
           )}

        _ ->
          # TODO : add some necessary timeout to avoid spamming...
          st = XestKraken.Adapter.servertime()

          {st,
           state
           |> Map.put(
             :servertime,
             st
           )}

          # otherwise skip
          #          {state.servertime, state}
      end
    end)

    #    # TODO : have some refresh to avoid too big a time skew...
    #    Agent.get_and_update(agent, fn state ->
    #      {state.shadow_clock,
    #       state |> Map.put(:shadow_clock, Xest.ShadowClock.update(state.shadow_clock))}
    #    end)
  end
end

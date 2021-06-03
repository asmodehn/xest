defmodule XestBinance.Exchange do
  @moduledoc """
  An Agent attempting to maintain a consistent view (as state) of the exchange
  It holds the knowledge of this system regarding binance.

  TODO: this is currently a separated process.
  Ultimately it should be the process the user starts.
  There is only logic here and this should be purely functional.
  There is no reason to keep state around when we can rebuild when needed,
   from past responses stored in server.
  """

  defmodule Behaviour do
    @moduledoc """
    Behaviour of Exchange, allowing other projects to mock XestBinance.Exchange for tests.
    """

    @type status :: XestBinance.Exchange.Status.t()
    @type reason :: String.t()

    @type servertime :: Xest.ShadowClock.t()
    @type mockable_pid :: nil | pid()

    # | {:error, reason}
    @callback status(mockable_pid()) :: status

    # | {:error, reason}
    @callback servertime(mockable_pid()) :: servertime

    # TODO : by leveraging __using__ we could implement default function
    #

    # TODO : move this to Exchange module (out of subdir - confusing).
    # This is only used for Mock testing of agent anyway, which means internally.
  end

  @behaviour Behaviour

  @default_minimum_request_period ~T[00:00:01]

  # these are the minimal amount of state necessary
  # to estimate current real world binance exchange status
  @enforce_keys [:minimal_request_period, :shadow_clock]
  defstruct status: nil,
            # pointing to the binance client pid
            client: nil,
            # TODO : maybe in model instead ?
            shadow_clock: nil,
            servertime: nil,
            minimal_request_period: @default_minimum_request_period,
            # TODO
            ping_timer: nil

  @typedoc "A exchange data structure, used as a local proxy for the actual exchange"
  @type t() :: %__MODULE__{
          status: Exchange.Status.t() | nil,
          # TODO: Xest.Ports.BinanceClientBehaviour.t() | nil,
          client: any(),
          # TODO : refine
          servertime: any(),
          shadow_clock: Xest.ShadowClock.t() | nil,
          minimal_request_period: Time.t() | nil
        }

  use Agent

  def start_link(opts, minimal_request_period \\ @default_minimum_request_period) do
    {client, opts} = Keyword.pop(opts, :client, XestBinance.Adapter.client())
    # REMINDER : we dont want to call external systems on startup.
    # Other processes need to align before this can safely happen in various environments.
    {clock, opts} =
      Keyword.pop(
        opts,
        :clock,
        Xest.ShadowClock.new(fn ->
          XestBinance.Adapter.servertime(client).servertime
        end)
      )

    # starting the agent by passing the struct as initial value
    # - app can tune the minimal_request_period
    # - mocks should manually modify the initial struct if needed
    exchange_struct = %XestBinance.Exchange{
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
  @impl true
  def status(agent) do
    Agent.get_and_update(agent, fn state ->
      case state.status do
        status when is_nil(status) ->
          status = XestBinance.Adapter.system_status()
          new_state = state |> Map.put(:status, status)
          {status, new_state}

        status ->
          {status, state}
          # TODO : add a case to check for timeout to request again the status
      end
    end)
  end

  @impl true
  def servertime(agent) do
    Agent.get_and_update(agent, fn state ->
      case state.servertime do
        nil ->
          st = XestBinance.Adapter.servertime()

          {st,
           state
           |> Map.put(
             :servertime,
             st
           )}

        _ ->
          # TODO : add some necessary timeout to avoid spamming...
          st = XestBinance.Adapter.servertime()

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

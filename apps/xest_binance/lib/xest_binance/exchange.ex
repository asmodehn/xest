defmodule XestBinance.Exchange do
  @moduledoc """
  An Agent attempting to maintain a consistent view (as state) of the exchange
  It holds the knowledge of this system regarding binance.
  """
  alias XestBinance.Adapter

  defmodule Behaviour do
    @moduledoc """
    Behaviour of Exchange, allowing tests and other projects to mock XestBinance.Exchange.
    """

    @type status :: XestBinance.Exchange.Status.t()
    @type reason :: String.t()

    @type servertime :: Xest.ShadowClock.t()
    @type mockable_pid :: nil | pid()

    # | {:error, reason}
    @callback status(mockable_pid) :: status

    # | {:error, reason}
    @callback servertime(mockable_pid) :: servertime

    # TODO : by leveraging __using__ we could implement default function
    #
  end

  @behaviour Behaviour

  @default_minimum_request_period ~T[00:00:01]

  # these are the minimal amount of state necessary
  # to estimate current real world binance exchange status
  @enforce_keys [:minimal_request_period, :shadow_clock]
  # pointing to the binance client pid
  defstruct client: nil,
            # TODO : maybe in model instead ?
            shadow_clock: nil,
            minimal_request_period: @default_minimum_request_period,
            # TODO
            ping_timer: nil

  @typedoc "A exchange data structure, used as a local proxy for the actual exchange"
  @type t() :: %__MODULE__{
          client: XestBinance.Adapter.Client.t(),
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

  @doc """
  Access the state of the exchange agent.
  This encodes our knowledge of binance exchange
  """
  def state(agent) do
    Agent.get(agent, &Function.identity/1)
  end

  # TODO : reverse flow: have client subscribe to status topic
  @impl true
  def status(agent \\ __MODULE__) do
    # cached read-through on adapter
    # No need to keep a cache here

    Agent.get(agent, fn state ->
      Adapter.system_status(state.client)
    end)
  end

  # TODO : reverse flow: have client subscribe to servertime topic
  @impl true
  def servertime(agent \\ __MODULE__) do
    # cached read-through on adapter
    # No need to keep a cache here
    Agent.get(agent, fn state ->
      Adapter.servertime(state.client)
    end)
  end
end

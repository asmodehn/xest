defmodule XestKraken.Exchange do
  @moduledoc """
  An Agent attempting to maintain a consistent view (as state) of the exchange
  It holds the knowledge of this system regarding kraken.
  """
  alias XestKraken.Adapter

  @behaviour XestKraken.Exchange.Behaviour

  @public_client Adapter.Client.new(nil, nil)

  # these are the minimal amount of state necessary
  # to estimate current real world kraken exchange status
  # , :shadow_clock]
  @enforce_keys []
  # a public client by default
  defstruct client: @public_client

  @typedoc "A exchange data structure, used as a local proxy for the actual exchange"
  @type t() :: %__MODULE__{
          client: XestKraken.Adapter.Client.t() | nil
        }

  defmodule Behaviour do
    @moduledoc """
    A behaviour to allow mocks when multiprocess tests are not desired.
    """

    @type status :: XestKraken.Exchange.Status.t()
    @type reason :: String.t()

    @type servertime :: XestKraken.Exchange.ServerTime.t()
    @type mockable_pid :: nil | atom() | pid()

    # | {:error, reason}
    @callback status(mockable_pid) :: status

    # | {:error, reason}
    @callback servertime(mockable_pid) :: servertime

    # | {:error, reason}
    @callback symbols(mockable_pid) :: Map.t()

    # TODO : by leveraging __using__ we could implement default function
    #                                   and their unsafe counterparts maybe ?
  end

  use Agent

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    opts = Keyword.put_new(opts, :name, name)

    {client, opts} = Keyword.pop(opts, :client, @public_client)

    # REMINDER : we dont want to call external systems on startup.
    # Other processes need to align before this can safely happen in various environments.
    #    {clock, opts} =
    #      Keyword.pop(opts, :clock, Xest.ShadowClock.new(fn -> kraken_adapter().time!(client) end))

    # starting the agent by passing the struct as initial value
    # - mocks should manually modify the initial struct if needed
    exchange_struct = %XestKraken.Exchange{
      client: client
    }

    Agent.start_link(
      fn -> exchange_struct end,
      opts
    )
  end

  @doc """
  Access the state of the exchange agent.
  This encodes our knowledge of kraken exchange
  """
  def state(agent \\ __MODULE__) do
    Agent.get(agent, &Function.identity/1)
  end

  # TODO : reverse flow: have client subscribe to servertime topic
  @impl true
  def status(agent \\ __MODULE__) do
    # cached read-through on adapter
    # No need to keep a cache here
    Agent.get(agent, fn state ->
      Adapter.system_status(state.client)
    end)
  end

  #  # TODO : reverse flow: have client subscribe to servertime topic
  @impl true
  def servertime(agent \\ __MODULE__) do
    # direct access to adapter, maybe not needed...
    # For a simulated/proxy local clock, use XestKraken.clock
    Agent.get(agent, fn state ->
      Adapter.servertime(state.client)
    end)
  end

  # access to all symbols available on hte (SPOT) exchange
  @impl true
  def symbols(agent \\ __MODULE__) do
    Agent.get(agent, fn state ->
      Adapter.asset_pairs(state.client)
    end)
  end
end

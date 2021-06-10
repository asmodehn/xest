defmodule XestKraken.Auth do
  @moduledoc """
    The private part of the client (specific to an account, should not be cached)

  """
  use GenServer

  defmodule Behaviour do
    @moduledoc """
      this implements a conversion from Kraken model into our Xest model.
      It serves to specify the types that must be exposed by a GenServer,
      where a better type can provide useful semantics.
      But it remains tied to the Binance model in its overall structure.
    """

    # TODO
    @type account :: Map.t()
    @type reason :: String.t()

    @type mockable_pid :: nil | pid()

    # | {:error, reason}
    @callback balance(mockable_pid()) :: {:ok, map()}

    @callback balance!(mockable_pid()) :: map()

    # TODO : by leveraging __using__ we could implement default function
    #                                   and their unsafe counterparts maybe ?
  end

  @behaviour Behaviour

  defstruct some_periodic_ping: "TODO",
            # will be defined on init (dynamically upon starting)
            # TODO : this doesnt need to be exposed, dependency switch can be done dynamically via config...
            kraken_client_adapter: nil,
            kraken_client_adapter_state: nil

  @doc """
  Starts reliable binance client.
  """
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    opts = Keyword.put_new(opts, :name, name)

    {endpoint, opts} = Keyword.pop(opts, :endpoint)
    {apikey, opts} = Keyword.pop(opts, :apikey)
    {secret, opts} = Keyword.pop(opts, :secret)

    GenServer.start_link(
      __MODULE__,
      # passing next_ping_wait_time in case it is specified as option from supervisor
      %__MODULE__{
        kraken_client_adapter: XestKraken.Adapter,
        kraken_client_adapter_state: XestKraken.Adapter.client(apikey, secret, endpoint)
      },
      opts
    )
  end

  ## Defining GenServer Callbacks
  @impl true
  def init(%__MODULE__{} = state) do
    # no ping to start
    {:ok, state}
  end

  #  def init({:ok, %__MODULE__{next_ping_wait_time: _next_ping_wait_time} = state}) do
  #    # scheduling ping onto itself
  #    state = reschedule_ping(state)
  #
  #    # just passing state as created in start_link
  #    {:ok, state}
  #  end

  @impl true
  def balance!(pid \\ __MODULE__) do
    {:ok, response} = balance(pid)
    response
  end

  @impl true
  def balance(pid \\ __MODULE__) do
    {:ok, balancemap} = GenServer.call(pid, {:balance})

    # a way to broadcast "low-level" events (we don't need to store them)
    #    Phoenix.PubSub.broadcast_from!(Xest.PubSub, self(), "binance:system_status", response)

    {:ok, balancemap}
  end

  @impl true
  def handle_call(
        {:balance},
        _from,
        %{
          kraken_client_adapter: kraken_client_adapter,
          kraken_client_adapter_state: kraken_client_adapter_state
        } = state
      ) do
    resp = kraken_client_adapter.balance(kraken_client_adapter_state)
    # TODO reschedule ping after request
    {:reply, resp, state}
  end
end

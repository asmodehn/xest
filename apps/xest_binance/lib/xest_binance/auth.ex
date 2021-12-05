defmodule XestBinance.Auth do
  @moduledoc """
    The private part of the client (specific to an account, should not be cached)

  """
  use GenServer

  defmodule Behaviour do
    @moduledoc """
      this implements a conversion from Binance model into our Xest model.
      It serves to specify the types that must be exposed by a GenServer,
      where a better type can provide useful semantics.
      But it remains tied to the Binance model in its overall structure.
    """

    # TODO
    @type account :: map()
    @type reason :: String.t()

    @type mockable_pid :: nil | pid()

    # | {:error, reason}
    @callback account(mockable_pid()) :: {:ok, %Binance.Account{}}

    @callback account!(mockable_pid()) :: %Binance.Account{}

    # | {:error, reason}
    @callback trades(mockable_pid(), String.t()) :: {:ok, [%Binance.Trade{}]}

    @callback trades!(mockable_pid(), String.t()) :: [%Binance.Trade{}]

    # TODO : by leveraging __using__ we could implement default function
    #                                   and their unsafe counterparts maybe ?
  end

  @behaviour Behaviour

  defstruct some_periodic_ping: "TODO",
            # will be defined on init (dynamically upon starting)
            binance_client: nil

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
        binance_client: XestBinance.Adapter.client(apikey, secret, endpoint)
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
  def account!(pid \\ __MODULE__) do
    {:ok, response} = account(pid)
    response
  end

  @impl true
  def account(pid \\ __MODULE__) do
    {:ok, account_model} = GenServer.call(pid, {:account})

    # a way to broadcast "low-level" events (we don't need to store them)
    #    Phoenix.PubSub.broadcast_from!(Xest.PubSub, self(), "binance:system_status", response)

    {:ok, account_model}
  end

  @impl true
  def trades!(pid \\ __MODULE__, symbol) when is_binary(symbol) do
    {:ok, response} = trades(pid, symbol)
    response
  end

  @impl true
  def trades(pid \\ __MODULE__, symbol) when is_binary(symbol) do
    {:ok, trades_model} = GenServer.call(pid, {:trades, symbol})

    # a way to broadcast "low-level" events (we don't need to store them)
    #    Phoenix.PubSub.broadcast_from!(Xest.PubSub, self(), "binance:system_status", response)

    {:ok, trades_model}
  end

  @impl true
  def handle_call(
        {:account},
        _from,
        %{
          binance_client: binance_client
        } = state
      ) do
    resp = XestBinance.Adapter.account(binance_client)
    # TODO reschedule ping after request
    {:reply, resp, state}
  end

  @impl true
  def handle_call(
        {:trades, symbol},
        _from,
        %{
          binance_client: binance_client
        } = state
      ) do
    resp = XestBinance.Adapter.trades(binance_client, symbol)
    # TODO reschedule ping after request
    {:reply, resp, state}
  end
end

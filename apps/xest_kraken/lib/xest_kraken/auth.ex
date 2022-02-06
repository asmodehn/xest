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
      But it remains tied to the Kraken model in its overall structure.
    """

    # TODO
    @type account :: map()
    @type reason :: String.t()

    @type mockable_pid :: nil | pid()

    # | {:error, reason}
    @callback balance(mockable_pid()) :: {:ok, XestKraken.Account.Balance.t()}

    @callback balance!(mockable_pid()) :: XestKraken.Account.Balance.t()

    @callback trades(mockable_pid()) :: {:ok, map()}
    @callback trades!(mockable_pid()) :: map()

    # TODO : by leveraging __using__ we could implement default function
    #                                   and their unsafe counterparts maybe ?
  end

  @behaviour Behaviour

  defstruct some_periodic_ping: "TODO",
            # will be defined on init (dynamically upon starting)
            kraken_client: nil,
            adapter: nil

  @doc """
  Starts reliable kraken client.
  """
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    opts = Keyword.put_new(opts, :name, name)

    {endpoint, opts} = Keyword.pop(opts, :endpoint)
    {apikey, opts} = Keyword.pop(opts, :apikey)
    {secret, opts} = Keyword.pop(opts, :secret)

    {adapter, opts} = Keyword.pop(opts, :adapter, XestKraken.Adapter)

    GenServer.start_link(
      __MODULE__,
      # passing next_ping_wait_time in case it is specified as option from supervisor
      %__MODULE__{
        kraken_client: adapter.client(apikey, secret, endpoint),
        adapter: adapter
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

    balances =
      XestKraken.Account.Balance.new(%{
        balances:
          balancemap
          |> Enum.map(fn {k, v} -> XestKraken.Account.AssetBalance.new(%{asset: k, amount: v}) end)
      })

    # TODO : maybe move this type wrapping to a lower level (adapter)...

    # a way to broadcast "low-level" events (we don't need to store them)
    #    Phoenix.PubSub.broadcast_from!(Xest.PubSub, self(), "binance:system_status", response)

    {:ok, balances}
  end

  @impl true
  def trades!(pid \\ __MODULE__) do
    {:ok, response} = trades(pid)
    response
  end

  @impl true
  def trades(pid \\ __MODULE__) do
    # TODO : proper paging implementation (count stuff)
    {:ok, %{"count" => _count, "trades" => tradesmap}} = GenServer.call(pid, {:trades})

    tradesmap =
      XestKraken.Account.Trades.new(%{
        trades:
          tradesmap
          |> Enum.map(fn {k, v} -> {k, v |> XestKraken.Account.Trade.new()} end)
          |> Enum.into(%{})
      })

    # TODO : maybe move this type wrapping to a lower level (adapter)...

    # a way to broadcast "low-level" events (we don't need to store them)
    #    Phoenix.PubSub.broadcast_from!(Xest.PubSub, self(), "binance:system_status", response)

    {:ok, tradesmap}
  end

  @impl true
  def handle_call(
        {:balance},
        _from,
        %{
          kraken_client: kraken_client,
          adapter: adapter
        } = state
      ) do
    resp = adapter.balance(kraken_client)
    # TODO reschedule ping after request
    {:reply, resp, state}
  end

  @impl true
  def handle_call(
        {:trades},
        _from,
        %{
          kraken_client: kraken_client,
          adapter: adapter
        } = state
      ) do
    resp = adapter.trades(kraken_client)
    # TODO reschedule ping after request
    {:reply, resp, state}
  end
end

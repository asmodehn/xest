defmodule XestBinance.Authenticated do
  @moduledoc """
    The private part of the client (specific to an account, should not be cached)

  """
  use GenServer

  @behaviour XestBinance.Ports.AuthenticatedBehaviour

  defstruct some_periodic_ping: "TODO",
            # will be defined on init (dynamically upon starting)
            binance_client_adapter: nil,
            binance_client_adapter_state: nil

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
        binance_client_adapter: client(),
        binance_client_adapter_state: client().new(apikey, secret, endpoint)
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

  defp client() do
    # config based on mix environment
    Application.get_env(:xest, :binance_client_adapter)
  end

  @impl true
  def handle_call(
        {:account},
        _from,
        %{
          binance_client_adapter: binance_client_adapter,
          binance_client_adapter_state: binance_client_adapter_state
        } = state
      ) do
    resp = binance_client_adapter.get_account(binance_client_adapter_state)
    # TODO reschedule ping after request
    {:reply, resp, state}
  end
end

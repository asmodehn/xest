defmodule XestBinance.Server do
  use GenServer

  @moduledoc """
  This is a genserver storing the technical state of the HTTP client to binance.
  This relies on a chosen http library for the binance adapter.
  """

  @behaviour XestBinance.Ports.ServerBehaviour

  #  def process_lookup(), do: {Xest.BinanceRegistry, "client"}
  #
  #  # TODO : maybe have a counter to detect restarts ? maybe last started time ?
  #  def process_registration(value), do: process_lookup() |> Tuple.append(value)

  # baking in sensible defaults
  @next_ping_wait_time_default :timer.seconds(60)
  def next_ping_wait_time_default(), do: @next_ping_wait_time_default

  # defining a struct as the state managed by the genserver
  defstruct next_ping_wait_time: @next_ping_wait_time_default,
            next_ping_ref: nil,
            # will be defined on init (dynamically upon starting)
            binance_client_adapter: nil

  @doc """
  Starts reliable binance client.
  """
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    opts = Keyword.put_new(opts, :name, name)

    {next_ping_wait_time, opts} =
      Keyword.pop(opts, :next_ping_wait_time, @next_ping_wait_time_default)

    GenServer.start_link(
      __MODULE__,
      {
        # TODO : remove this (useless here)
        :ok,
        # passing next_ping_wait_time in case it is specified as option from supervisor
        %__MODULE__{} |> Map.put(:next_ping_wait_time, next_ping_wait_time)
      },
      opts
    )
  end

  def next_ping_schedule(pid \\ __MODULE__, next_timer_period \\ nil) do
    GenServer.call(pid, {:next_ping_schedule, next_timer_period})
  end

  @impl true
  def system_status!(pid \\ __MODULE__) do
    {:ok, response} = system_status(pid)
    response
  end

  @impl true
  def system_status(pid \\ __MODULE__) do
    {:ok, %{"msg" => msg, "status" => status}} = GenServer.call(pid, {:system_status})

    response = %XestBinance.Models.ExchangeStatus{message: msg, code: status}

    # a way to broadcast "low-level" events (we don't need to store them)
    Phoenix.PubSub.broadcast_from!(Xest.PubSub, self(), "binance:system_status", response)

    {:ok, response}
  end

  @impl true
  def time!(pid \\ __MODULE__) do
    {:ok, response} = time(pid)
    response
  end

  @impl true
  def time(pid \\ __MODULE__) do
    {:ok, %{"serverTime" => servertime}} = GenServer.call(pid, {:time})
    response = servertime |> DateTime.from_unix!(:millisecond)

    # a way to broadcast "low-level" events (we don't need to store them)
    Phoenix.PubSub.broadcast_from!(Xest.PubSub, self(), "binance:time", response)

    {:ok, response}
  end

  ## Defining GenServer Callbacks
  @impl true
  def init({:ok, %__MODULE__{next_ping_wait_time: nil} = state}) do
    # no ping to start
    init({:ok, %__MODULE__{state | next_ping_wait_time: nil}})
  end

  def init({:ok, %__MODULE__{next_ping_wait_time: _next_ping_wait_time} = state}) do
    binance_client_adapter = Application.get_env(:xest, :binance_client_adapter)

    # scheduling ping onto itself
    state = reschedule_ping(state)

    # TMP no state for now, except the adapter for dynamic dispatch
    # => lets try to manage everything with tesla...
    {:ok, %__MODULE__{state | binance_client_adapter: binance_client_adapter}}
  end

  defp reschedule_ping(%__MODULE__{next_ping_ref: nil, next_ping_wait_time: nil} = state),
    do: state

  defp reschedule_ping(
         %__MODULE__{next_ping_ref: nil, next_ping_wait_time: next_ping_wait_time} = state
       ) do
    # reschedule ping onto itself
    timer_ref = Process.send_after(self(), :ping, next_ping_wait_time)

    # we keep the same wait time for the next ping
    %__MODULE__{
      state
      | next_ping_ref: timer_ref,
        next_ping_wait_time: next_ping_wait_time
    }
  end

  defp reschedule_ping(%__MODULE__{next_ping_ref: previous_timer_ref} = state) do
    Process.cancel_timer(previous_timer_ref)
    reschedule_ping(%__MODULE__{state | next_ping_ref: nil})
  end

  @impl true
  def handle_info(:ping, %{binance_client_adapter: binance_client_adapter} = state) do
    {:ok, %{}} = binance_client_adapter.ping()
    # TODO :if ping fail, we should probably crash the genserver...

    # reschedule ping after request
    {:noreply, reschedule_ping(state)}
  end

  @impl true
  def handle_call(
        {:next_ping_schedule, nil},
        _from,
        %{next_ping_ref: next_ping_ref, next_ping_wait_time: next_ping_wait_time} = state
      ) do
    {:reply, %{next_ping_ref: next_ping_ref, next_ping_wait_time: next_ping_wait_time}, state}
  end

  @impl true
  def handle_call(
        {:next_ping_schedule, next_timer_period},
        _from,
        %{next_ping_ref: next_ping_ref, next_ping_wait_time: _next_ping_wait_time} = state
      ) do
    {:reply, %{next_ping_ref: next_ping_ref, next_ping_wait_time: next_timer_period}, state}
  end

  @impl true
  def handle_call(
        {:system_status},
        _from,
        %{binance_client_adapter: binance_client_adapter} = state
      ) do
    resp = binance_client_adapter.system_status()
    # reschedule ping after request
    {:reply, resp, reschedule_ping(state)}
  end

  @impl true
  def handle_call({:time}, _from, %{binance_client_adapter: binance_client_adapter} = state) do
    resp = binance_client_adapter.time()
    # reschedule ping after request
    {:reply, resp, reschedule_ping(state)}
  end
end
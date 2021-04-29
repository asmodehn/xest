# TODO: change name too confusing with actual http client
defmodule Xest.BinanceClient do
  use GenServer

  @moduledoc """
  This is a genserver storing the technical state of the HTTP client to binance.
  This relies on a chosen http library for the binance adapter.
  """

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
    {next_ping_wait_time, opts} =
      Keyword.pop(opts, :next_ping_wait_time, @next_ping_wait_time_default)

    GenServer.start_link(
      __MODULE__,
      {
        :ok,
        # passing next_ping_wait_time in case it is specified as option from supervisor
        %Xest.BinanceClient{%Xest.BinanceClient{} | next_ping_wait_time: next_ping_wait_time}
      },
      opts
    )
  end

  def next_ping_schedule(pid \\ __MODULE__, next_timer_period \\ nil) do
    # TODO next_timer_period to be able to change it
    GenServer.call(pid, {:next_ping_schedule, next_timer_period})
  end

  def system_status(pid \\ __MODULE__) do
    GenServer.call(pid, {:system_status})
  end

  def time(pid \\ __MODULE__) do
    GenServer.call(pid, {:time})
  end

  ## Defining GenServer Callbacks
  @impl true
  def init({:ok, %Xest.BinanceClient{next_ping_wait_time: nil} = state}) do
    # no ping to start
    init({:ok, %Xest.BinanceClient{state | next_ping_wait_time: nil}})
  end

  def init({:ok, %Xest.BinanceClient{next_ping_wait_time: next_ping_wait_time} = state}) do
    binance_client_adapter = Application.get_env(:xest, :binance_client_adapter)

    # scheduling ping onto itself
    state = reschedule_ping(state)

    # TMP no state for now, except the adapter for dynamic dispatch
    # => lets try to manage everything with tesla...
    {:ok, %Xest.BinanceClient{state | binance_client_adapter: binance_client_adapter}}
  end

  defp reschedule_ping(%Xest.BinanceClient{next_ping_ref: nil, next_ping_wait_time: nil} = state),
    do: state

  defp reschedule_ping(
         %Xest.BinanceClient{next_ping_ref: nil, next_ping_wait_time: next_ping_wait_time} = state
       ) do
    # reschedule ping onto itself
    timer_ref = Process.send_after(self(), :ping, next_ping_wait_time)

    # we keep the same wait time for the next ping
    %Xest.BinanceClient{
      state
      | next_ping_ref: timer_ref,
        next_ping_wait_time: next_ping_wait_time
    }
  end

  defp reschedule_ping(%Xest.BinanceClient{next_ping_ref: previous_timer_ref} = state) do
    Process.cancel_timer(previous_timer_ref)
    reschedule_ping(%Xest.BinanceClient{state | next_ping_ref: nil})
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
        %{next_ping_ref: next_ping_ref, next_ping_wait_time: next_ping_wait_time} = state
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

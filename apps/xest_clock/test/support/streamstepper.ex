defmodule StreamStepper do
  @moduledoc """
      A simple GenServer allowing taking one element at a time from a stream
  """
  alias XestClock.Stream.Ticker

  use GenServer

  def start_link(enumerable, options \\ []) when is_list(options) do
    GenServer.start_link(__MODULE__, enumerable, options)
  end

  @impl true
  def init(enumerable) do
    {:ok, Ticker.new(enumerable)}
  end

  def tick(pid) do
    List.first(ticks(pid, 1))
  end

  def ticks(pid, demand) do
    GenServer.call(pid, {:steps, demand})
  end

  @impl true
  def handle_call({:steps, demand}, _from, ticker) do
    {result, new_ticker} = Ticker.next(demand, ticker)
    {:reply, result, new_ticker}
  end
end

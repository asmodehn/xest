defmodule ExampleServer do
  use XestClock.Server
  # use will setup the correct streamclock for leveraging the `handle_remote_unix_time` callback
  # the unit passed as parameter will be sent to handle_remote_unix_time

  # Client code

  # already defined in macro. good or not ?
  @impl true
  def start_link(unit, opts \\ []) when is_list(opts) do
    XestClock.Server.start_link(__MODULE__, unit, opts)
  end

  @impl true
  def init(state) do
    XestClock.Server.init(state, &handle_remote_unix_time/1)
  end

  def tick(pid \\ __MODULE__) do
    List.first(ticks(pid, 1))
  end

  @impl true
  def ticks(pid \\ __MODULE__, demand) do
    XestClock.Server.ticks(pid, demand)
  end

  def monotonic_time(pid \\ __MODULE__, unit) do
    XestClock.Server.monotonic_time(pid, unit)
  end

  ## Callbacks
  @impl true
  def handle_remote_unix_time(unit) do
    XestClock.Time.Value.new(:second, 42)
    |> XestClock.Time.Value.convert(unit)
  end
end

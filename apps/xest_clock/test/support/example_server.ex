defmodule ExampleServer do
  use XestClock.Server

  require XestClock.System
  require XestClock.Time
  # TODO : alias better ?
  # TODO : better to put in use or not ?

  # use will setup the correct streamclock for leveraging the `handle_remote_unix_time` callback
  # the unit passed as parameter will be sent to handle_remote_unix_time

  # Client code

  # already defined in macro. good or not ?
  def start_link(opts \\ []) when is_list(opts) do
    XestClock.Server.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_state) do
    XestClock.Server.init(
      # TODO : maybe we can get rid of this for test ???
      XestClock.Stream.repeatedly_throttled(
        # default period limit of a second
        1000,
        &handle_remote_unix_time/0
      )
    )
  end

  def tick(pid \\ __MODULE__) do
    List.first(ticks(pid, 1))
  end

  @impl true
  def ticks(pid \\ __MODULE__, demand) do
    XestClock.Server.ticks(pid, demand)
  end

  ## Callbacks
  @impl true
  def handle_offset(state) do
    {result, new_state} = XestClock.Server.compute_offset(state)
    {result, new_state}
  end

  @impl true
  def handle_remote_unix_time() do
    XestClock.Time.Value.new(
      :second,
      XestClock.System.monotonic_time(:second)
    )
  end

  def monotonic_time(pid \\ __MODULE__, unit) do
    XestClock.Server.monotonic_time(pid, unit)
  end
end

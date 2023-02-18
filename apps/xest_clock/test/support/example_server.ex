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
  #  def start_link(stream, opts \\ []) when is_list(opts) do
  #    XestClock.Server.start_link(__MODULE__, stream, opts)
  #  end

  # we redefine init to setup our own constraints on throttling
  def init(timevalue_stream) do
    XestClock.Server.init(
      # TODO : maybe we can get rid of this for test ???
      XestClock.Stream.repeatedly_throttled(
        # default period limit of a second
        1000,
        timevalue_stream
      )
    )
  end

  def tick(pid \\ __MODULE__) do
    List.first(ticks(pid, 1))
  end

  # in case we want to expose internal ticks to the client
  def ticks(pid \\ __MODULE__, demand) do
    XestClock.Server.StreamStepper.ticks(pid, demand)
  end

  def monotonic_time(pid \\ __MODULE__, unit) do
    XestClock.Server.monotonic_time(pid, unit)
  end

  ## Callbacks
  @impl XestClock.Server
  def handle_offset(state) do
    {result, new_state} = XestClock.Server.compute_offset(state)
    {result, new_state}
  end
end

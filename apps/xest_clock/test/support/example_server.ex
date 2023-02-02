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

  ## Callbacks
  @impl true
  def handle_remote_unix_time(unit) do
    case unit do
      :second -> 42
      :millisecond -> 42_000
      :microsecond -> 42_000_000
      :nanosecond -> 42_000_000_000
      # default and parts per seconds
      pps -> 42 * pps
    end
  end
end

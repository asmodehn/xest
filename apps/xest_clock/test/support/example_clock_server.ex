defmodule XestClock.ExampleClockServer do
  use XestClock.ClockServer
  #   :remote_atom, :millisecond

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def tick(pid \\ __MODULE__) do
    List.first(GenServer.call(pid, {:ticks, 1}))
  end

  #  @impl true
  #  def ticks(pid \\ __MODULE__, demand) do
  #    GenServer.call(pid, {:ticks, demand})
  #  end

  @impl true
  def handle_remote_unix_time(_unit) do
    42
  end
end

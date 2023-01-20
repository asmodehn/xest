defmodule XestClock.Server.Local do
  @moduledoc """
    A Local clock gen server, useful in itself, as well as an example of usage of `XestClock.Server` module.

    See `XestClock.Server` for more information about using it to define your custom remote clocks.
  """

  use XestClock.Server

  ## Client functions
  @impl true
  def start_link(unit, opts \\ []) when is_list(opts) do
    XestClock.Server.start_link(__MODULE__, unit, opts)
  end

  @impl true
  def ticks(pid \\ __MODULE__, demand) do
    XestClock.Server.ticks(pid, demand)
  end

  # TODO : here or somewhere else ??
  # TODO : CAREFUL to get a utc time, not a monotonetime...
  @spec utc_now(pid()) :: XestClock.Timestamp.t()
  def utc_now(pid \\ __MODULE__) do
    List.first(XestClock.Server.ticks(pid, 1))
    # TODO : offset from monotone time maybe ?? or earlier in stream ?
    # Later: what about skew ??
  end

  ## Callbacks
  @impl true
  def handle_remote_unix_time(unit) do
    # TODO : monotonic time.
    # TODO : find a nice way to deal with the offset...
    XestClock.System.system_time(unit)
  end
end

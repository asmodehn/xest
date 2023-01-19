Mix.install([
  {:req, "~> 0.3"},
  {:xest_clock, path: "../xest_clock"}
])

defmodule WorldClockAPI do
  @moduledoc """
    A module providing a local proxy of (part of) worldclockapi.org via `XestClock.Server`
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
    # Note: unixtime is not monotonic.
    # But the internal clock stream will enforce it.
    response =
      Req.get!("http://worldtimeapi.org/api/timezone/Etc/UTC", cache: false) |> IO.inspect()

    unixtime = response.body["unixtime"]

    case unit do
      :second -> unixtime
      :millisecond -> unixtime * 1_000
      :microsecond -> unixtime * 1_000_000
      :nanosecond -> unixtime * 1_000_000_000
      pps -> div(unixtime * pps, 1000)
    end
  end
end

{:ok, worldclock_pid} = WorldClockAPI.start_link(:second)

# TODO : periodic permanent output...
# IO.puts(
unixtime = List.first(WorldClockAPI.ticks(worldclock_pid, 1))
IO.inspect(XestClock.NewWrapper.DateTime.from_unix!(unixtime.ts, unixtime.unit))
# )

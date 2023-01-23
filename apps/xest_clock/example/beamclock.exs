Mix.install(
  [
    {:req, "~> 0.3"},
    {:xest_clock, path: "../xest_clock"}
  ],
  consolidate_protocols: true
)

defmodule BeamClock do
  @moduledoc """
    The Clock of the BEAM, as if it wer a clock on a remote system...
  This is not an example of how to do things, but rather an usecase to validate the API design.

  In theory, a user intersting in a clock should be able to use a remote clock or a local on in the same way.
  The only difference is that we can optimise the access to the local one,
    which is the default we have grown accustomed to in most "local-first" systems.

  `XestClock` proposes an API that works for both local and remote clocks, and is closer to purity,
    therefore more suitable for usage by distributed apps.
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

{:ok, beamclock_pid} = BeamClock.start_link(:second)

# TODO : periodic permanent output...

# for ticks <- WorldClockAPI.ticks(worldclock_pid, 5) do
# IO.puts(ticks)
# end

unixtime = List.first(BeamClock.ticks(beamclock_pid, 1))
IO.puts(unixtime)

# IO.inspect(XestClock.NewWrapper.DateTime.from_unix!(unixtime.ts, unixtime.unit))

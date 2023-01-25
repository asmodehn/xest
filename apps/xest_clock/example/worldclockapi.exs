Mix.install(
  [
    {:ratatouille, "~> 0.5"},
    {:req, "~> 0.3"},
    {:xest_clock, path: "../xest_clock"}
  ],
  consolidate_protocols: true
)

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
    # Note: unixtime on worldtime api might not be monotonic...
    # But the internal clock stream will enforce it !
    response = Req.get!("http://worldtimeapi.org/api/timezone/Etc/UTC", cache: false)
    #      |> IO.inspect()

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

# for ticks <- WorldClockAPI.ticks(worldclock_pid, 5) do
# IO.puts(ticks)
# end

unixtime = List.first(WorldClockAPI.ticks(worldclock_pid, 1))
IO.puts(unixtime)

# IO.inspect(XestClock.NewWrapper.DateTime.from_unix!(unixtime.ts, unixtime.unit))

defmodule WorldClockApp do
  @behaviour Ratatouille.App

  import Ratatouille.View
  alias Ratatouille.Runtime.Subscription

  @impl true
  def init(context) do
    IO.inspect(context)

    {:ok, beamclock_pid} = WorldClockAPI.start_link(:second)
    model = %{clock_pid: beamclock_pid, now: WorldClockAPI.utc_now(beamclock_pid)}
    model
  end

  @impl true
  def subscribe(_model) do
    Subscription.interval(1_000, :tick)
  end

  @impl true
  def update(%{clock_pid: beamclock_pid, now: _now} = model, msg) do
    # TODO : send periodic ticks to xest_clock server
    # passively? actively ? both ?
    case msg do
      :tick ->
        unixtime = WorldClockAPI.utc_now(beamclock_pid)
        %{model | now: unixtime}

      _ ->
        IO.inspect("unhandled message: #{msg}")
        model
    end
  end

  @impl true
  def render(%{clock_pid: _pid, now: now}) do
    view do
      panel(title: "Received Monotonic Time") do
        # TODO : find a way to get notified of it (maybe bypassing the stream for introspection ?)
      end

      # TODO : extra panel to "view" proxy computation
      panel(title: "Locally Computed Time") do
        table do
          table_row do
            table_cell(content: "now")
          end

          table_row do
            table_cell(content: to_string(now))
          end
        end
      end
    end
  end
end

Ratatouille.run(WorldClockApp)

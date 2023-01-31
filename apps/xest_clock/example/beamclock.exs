Mix.install(
  [
    {:ratatouille, "~> 0.5"},
    {:req, "~> 0.3"},
    {:xest_clock, path: "../xest_clock"}
  ],
  consolidate_protocols: true
)

defmodule BeamClock do
  @moduledoc """
    The Clock of the BEAM, as if it were a clock on a remote system...
  This is not an example of how to do things, but rather an usecase to validate the API design.

  In theory, a user interested in a clock should be able to use a remote clock or a local on in the same way.
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
    XestClock.System.monotonic_time(unit)
  end
end

defmodule BeamClockApp do
  @behaviour Ratatouille.App

  import Ratatouille.View
  alias Ratatouille.Runtime.Subscription

  @impl true
  def init(context) do
    IO.inspect(context)

    {:ok, beamclock_pid} = BeamClock.start_link(:second)
    model = %{clock_pid: beamclock_pid, now: BeamClock.utc_now(beamclock_pid)}
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
        unixtime = BeamClock.utc_now(beamclock_pid)
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
            table_cell(content: "remote")
            table_cell(content: "local")
          end

          table_row do
            table_cell(content: to_string(elem(now, 0) |> Map.get(:ts) |> Map.get(:monotonic)))

            table_cell(
              content: to_string(elem(now, 1) |> Map.get(:monotonic) |> Map.get(:monotonic))
            )

            # protocol String.Chars doesnt work ??
            #            table_cell(content: to_string(now |>elem(0)))
            #            table_cell(content: to_string(now |>elem(1)))
          end
        end
      end
    end
  end
end

Ratatouille.run(BeamClockApp)

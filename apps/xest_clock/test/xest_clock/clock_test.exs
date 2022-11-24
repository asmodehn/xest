defmodule XestClock.Clock.Test do
  use ExUnit.Case
  doctest XestClock.Clock

  alias XestClock.Clock

  @doc """
  util function to always pattern match on timestamps
  """
  def ts_retrieve(origin, unit) do
    fn ticks ->
      ts_stream =
        for t <- ticks do
          %Clock.Timestamp{
            origin: ^origin,
            ts: ts,
            unit: ^unit
          } = t

          ts
        end
    end
  end

  describe "XestClock.Clock" do
    test "new(:local, time_unit) generates local clock with custom time_unit" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clock = Clock.new(:local, unit)
        assert clock.origin == :local
        assert clock.unit == unit
      end
    end

    test "new/2 refuses :native or unknown time units" do
      assert_raise(ArgumentError, fn ->
        XestClock.Clock.new(:local, :native)
      end)

      assert_raise(ArgumentError, fn ->
        XestClock.Clock.new(:local, :unknown_time_unit)
      end)
    end

    test "tick/1 returns increasing timestamp for local clock" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clock = Clock.new(:local, unit)

        ts_list = ts_retrieve(:local, unit).(clock |> Enum.take(2) |> Enum.to_list())

        assert Enum.sort(ts_list, :asc) == ts_list
      end
    end

    test "tick/1 using list of integers stops at the first integer that is not greater than the current one" do
      clock = Clock.new(:testclock, :second, [1, 2, 3, 5, 4])

      assert ts_retrieve(:testclock, :second).(clock |> Stream.take(5) |> Enum.to_list()) == [
               1,
               2,
               3,
               5
             ]
    end

    test "tick/1 returns increasing timestamp for clock using agent update as read function" do
      #  A simple test ticker agent, that ticks everytime it is called
      # TODO : use start_supervised ??
      {:ok, clock_agent} =
        Agent.start_link(fn ->
          [1, 2, 3, 5, 4]
        end)

      ticker = fn ->
        Agent.get_and_update(
          clock_agent,
          fn [h | t] -> {h, t} end
        )
      end

      # NB : using an agent to store state is NOT similar to Stream.unfold(),
      # As all operations on a stream have to be done "at once",
      # and cannot "tick by tick", as possible when an agent stores the state.

      # The agent usecase is similar to what happens with the system clock.

      # However we *can encapsulate/abstract* the Agent (state-updating) request behaviour
      # with a stream repeatedly calling and updating the agent (as with the system clock)

      clock = Clock.new(:testclock, :nanosecond, ticker)

      assert ts_retrieve(:testclock, :nanosecond).(clock |> Stream.take(5) |> Enum.to_list()) == [
               1,
               2,
               3,
               5
             ]
    end

    # TODO, but as a stream of ticks
    #    test "tick/1 returns timestamp" do
    #      clock = Clock.new(:local_testclock, :nanosecond, [1, 2_000, 3_000_000, 4_000_000_000, 42])
    #
    #      assert Clock.tick(clock) ==  %Clock.Timestamp{
    #              origin: :local_testclock,
    #              ts: 1,
    #              unit: :nanosecond
    #            }
    #                  assert XestClock.Clock.tick(clock) ==  %Clock.Timestamp{
    #              origin: :local_testclock,
    #              ts: 2000,
    #              unit: :nanosecond
    #            }
    #                              assert XestClock.Clock.tick(clock) ==  %Clock.Timestamp{
    #              origin: :local_testclock,
    #              ts: 3_000_000,
    #              unit: :nanosecond
    #            }
    #                              assert XestClock.Clock.tick(clock) ==  %Clock.Timestamp{
    #              origin: :local_testclock,
    #              ts: 4_000_000_000,
    #              unit: :nanosecond
    #            }
    #    end

    #
    #    test "monotonic_time/2 returns clock time and convert between units", %{ticker: ticker} do
    #      clock = Clock.new(:local_testclock, :nanosecond, ticker)
    #
    #      assert Clock.monotonic_time(clock, :nanosecond) == 1
    #      assert Clock.monotonic_time(clock, :microsecond) == 2
    #      assert Clock.monotonic_time(clock, :millisecond) == 3
    #      assert Clock.monotonic_time(clock, :second) == 4
    #    end

    #
    #    test "stream returns a stream", %{ticker: ticker} do
    #      clock = Clock.new(:local_testclock, :nanosecond, ticker)
    #
    #      assert Clock.stream(clock, :nanosecond)
    #             |> Stream.take(4)
    #             |> Enum.to_list() == [
    #               1,
    #               2_000,
    #               3_000_000,
    #               4_000_000_000
    #             ]
    #    end
    #
    #    test "stream manages unit conversion", %{ticker: ticker} do
    #      clock = Clock.new(:local_testclock, :nanosecond, ticker)
    #
    #      assert Clock.stream(clock, :microsecond)
    #             |> Stream.take(4)
    #             |> Enum.to_list() == [
    #               # Note : only integer : lower precision is lost !
    #               0,
    #               2,
    #               3_000,
    #               4_000_000
    #             ]
    #    end
  end
end

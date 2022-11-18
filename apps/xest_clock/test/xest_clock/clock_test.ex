defmodule XestClock.Clock.Test do
  use ExUnit.Case
  doctest XestClock.Clock

  #  describe "XestClock.Remote.Clock" do
  #    setup do
  #      s = Stream.iterate(0, &(&1 + 1))
  #
  #      clock = XestClock.Clock.new(s, :millisecond)
  #      %{clock: clock}
  #    end
  #
  #    test "new/2 creates a stream of results of the function passed in arguments",
  #         %{clock: clock} do
  #      assert clock |> Stream.take(5) |> Enum.to_list() == [0, 1, 2, 3, 4]
  #      #        assert clock.accumulator == Task
  #    end
  #  end

  describe "XestClock.Clock" do
    test "new/0 generates local clock" do
      clock = XestClock.Clock.new()
      assert clock.origin == :local
      assert clock.unit == :native
    end

    test "new(:local, :native) generates local clock with native unit" do
      clock = XestClock.Clock.new(:local, :native)
      assert clock.origin == :local
      assert clock.unit == :native
    end

    test "new(:local, time_unit) generates local clock with custom time_unit" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clock = XestClock.Clock.new(:local, unit)
        assert clock.origin == :local
        assert clock.unit == unit
      end
    end

    test "new/2 refuses unknown time units" do
      assert_raise(ArgumentError, fn ->
        XestClock.Clock.new(:local, :unknown_time_unit)
      end)
    end

    setup do
      #  A simple test ticker agent, that ticks everytime it is called
      # TODO : use start_supervised
      {:ok, clock_agent} =
        Agent.start_link(fn ->
          # The ticks as a sequence
          [1, 2_000, 3_000_000, 4_000_000_000, 42]
          # Note : for stream we need one more than retrieved...
        end)

      ticker = fn ->
        Agent.get_and_update(
          clock_agent,
          fn [h | t] -> {h, t} end
        )
      end

      %{ticker: ticker}
    end

    test "monotonic_time/2 returns clock time and convert between units", %{ticker: ticker} do
      clock = XestClock.Clock.new(:local_testclock, :nanosecond, ticker)

      assert XestClock.Clock.monotonic_time(clock, :nanosecond) == 1
      assert XestClock.Clock.monotonic_time(clock, :microsecond) == 2
      assert XestClock.Clock.monotonic_time(clock, :millisecond) == 3
      assert XestClock.Clock.monotonic_time(clock, :second) == 4
    end

    test "stream returns a stream", %{ticker: ticker} do
      clock = XestClock.Clock.new(:local_testclock, :nanosecond, ticker)

      assert XestClock.Clock.stream(clock, :nanosecond)
             |> Stream.take(4)
             |> Enum.to_list() == [
               1,
               2_000,
               3_000_000,
               4_000_000_000
             ]
    end

    test "stream manages unit conversion", %{ticker: ticker} do
      clock = XestClock.Clock.new(:local_testclock, :nanosecond, ticker)

      assert XestClock.Clock.stream(clock, :microsecond)
             |> Stream.take(4)
             |> Enum.to_list() == [
               # Note : only integer : lower precision is lost !
               0,
               2,
               3_000,
               4_000_000
             ]
    end
  end
end

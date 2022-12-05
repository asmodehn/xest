defmodule XestClock.Clock.Stream.Test do
  use ExUnit.Case
  doctest XestClock.Clock.Stream

  alias XestClock.Timestamp

  @doc """
  util function to always pattern match on timestamps
  """
  def ts_retrieve(origin, unit) do
    fn ticks ->
      ts_stream =
        for t <- ticks do
          %Timestamp{
            origin: ^origin,
            ts: ts,
            unit: ^unit
          } = t

          ts
        end
    end
  end

  describe "XestClock.Clock.Stream" do
    test "stream/2 refuses :native or unknown time units" do
      assert_raise(ArgumentError, fn ->
        XestClock.Clock.Stream.new(:local, :native)
      end)

      assert_raise(ArgumentError, fn ->
        XestClock.Clock.Stream.new(:local, :unknown_time_unit)
      end)
    end

    test "stream/2 pipes increasing timestamp for local clock" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clock = XestClock.Clock.Stream.new(:local, unit)

        tick_list = clock |> Enum.take(2) |> Enum.to_list()

        assert Enum.sort(tick_list, :asc) == tick_list
      end
    end

    test "stream/3 stops at the first integer that is not greater than the current one" do
      clock = XestClock.Clock.Stream.new(:testclock, :second, [1, 2, 3, 5, 4])

      assert clock |> Enum.to_list() == [
               1,
               2,
               3,
               5
             ]
    end

    test "stream/3 returns increasing timestamp for clock using agent update as read function" do
      #  A simple test ticker agent, that ticks everytime it is called
      {:ok, clock_agent} =
        start_supervised(
          {Agent,
           fn ->
             [1, 2, 3, 5, 4]
           end}
        )

      ticker = fn ->
        Agent.get_and_update(
          clock_agent,
          fn
            # this is needed only if stream wants more elements than expected (infinitely ?)
            #            [] -> {nil, []}
            [h | t] -> {h, t}
          end
        )
      end

      # NB : using an agent to store state is NOT similar to Stream.unfold(),
      # As all operations on a stream have to be done "at once",
      # and cannot "tick by tick", as possible when an agent stores the state.

      # The agent usecase is similar to what happens with the system clock, or with a remote clock.

      # However we *can encapsulate/abstract* the Agent (state-updating) request behaviour
      # with a stream repeatedly calling and updating the agent (as with the system clock)

      clock =
        XestClock.Clock.Stream.new(
          :testclock,
          :nanosecond,
          Stream.repeatedly(fn -> ticker.() end)
        )

      # Note : we can take/2 only 4 elements (because of monotonicity constraint).
      # Attempting to take more will keep calling the ticker
      # and fail since the [] -> {nil, []} line is commented
      # TODO : taking more should stop the agent, and end the stream...
      assert clock |> Stream.take(4) |> Enum.to_list() == [
               1,
               2,
               3,
               5
             ]
    end

    test "as_timestamp/1 transform the clock stream into a stream of timestamps." do
      clock = XestClock.Clock.Stream.new(:testclock, :second, [1, 2, 3, 5, 4])

      assert ts_retrieve(:testclock, :second).(clock |> XestClock.Clock.Stream.as_timestamp()) ==
               [
                 1,
                 2,
                 3,
                 5
               ]
    end

    test "convert/2 convert from one unit to another" do
      clock = XestClock.Clock.Stream.new(:testclock, :second, [1, 2, 3, 5, 4])

      assert XestClock.Clock.Stream.convert(clock, :millisecond) |> Enum.to_list() == [
               1000,
               2000,
               3000,
               5000
             ]
    end

    test "offset/2 computes difference between clocks" do
      clockA = XestClock.Clock.Stream.new(:testclockA, :second, [1, 2, 3, 5, 4])
      clockB = XestClock.Clock.Stream.new(:testclockB, :second, [11, 12, 13, 15, 124])

      assert clockA |> XestClock.Clock.Stream.offset(clockB) ==
               %XestClock.Timestamp{origin: :testclockB, ts: 10, unit: :second}
    end

    test "offset/2 of same clock is null" do
      clockA = XestClock.Clock.Stream.new(:testclockA, :second, [1, 2, 3])
      clockB = XestClock.Clock.Stream.new(:testclockB, :second, [1, 2, 3])

      assert clockA |> XestClock.Clock.Stream.offset(clockB) ==
               %XestClock.Timestamp{origin: :testclockB, ts: 0, unit: :second}
    end
  end
end

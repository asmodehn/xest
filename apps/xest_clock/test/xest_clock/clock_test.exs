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

    test "Enum returns increasing timestamp for local clock" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clock = Clock.new(:local, unit)

        ts_list = ts_retrieve(:local, unit).(clock |> Enum.take(2) |> Enum.to_list())

        assert Enum.sort(ts_list, :asc) == ts_list
      end
    end

    test "Enum stops at the first integer that is not greater than the current one" do
      clock = Clock.new(:testclock, :second, [1, 2, 3, 5, 4])

      assert ts_retrieve(:testclock, :second).(clock |> Stream.take(5) |> Enum.to_list()) == [
               1,
               2,
               3,
               5
             ]
    end

    test "Enum returns increasing timestamp for clock using agent update as read function" do
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

    test "Enum can be zipped alongside another" do
      clock = Clock.new(:testclock, :second, [1, 2, 3, 5, 4])

      events = [:one, :two, :three, :five]

      assert clock |> Stream.zip(events) |> Enum.to_list() == [
               {%XestClock.Clock.Timestamp{origin: :testclock, ts: 1, unit: :second}, :one},
               {%XestClock.Clock.Timestamp{origin: :testclock, ts: 2, unit: :second}, :two},
               {%XestClock.Clock.Timestamp{origin: :testclock, ts: 3, unit: :second}, :three},
               {%XestClock.Clock.Timestamp{origin: :testclock, ts: 5, unit: :second}, :five}
             ]
    end
  end
end

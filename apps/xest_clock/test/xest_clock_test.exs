defmodule XestClockTest do
  use ExUnit.Case
  doctest XestClock

  describe "XestClock" do
    test "local/0 builds a nanosecond clock with a local key" do
      clk = XestClock.local()
      assert %XestClock.Clock{unit: :nanosecond} = clk.local
    end

    test "local/1 builds a clock with a local key" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clk = XestClock.local(unit)
        assert %XestClock.Clock{unit: ^unit} = clk.local
      end
    end

    test "remote/3 builds a remote clock with the origin key" do
      clk = XestClock.remote(:testclock, :nanosecond, [1, 2, 3, 4])

      assert %XestClock.Clock{origin: :testclock, unit: :nanosecond, read: [1, 2, 3, 4]} ==
               clk.testclock
    end
  end

  describe "XestClock inside a Process" do
    setup do
      {:ok, clock_agent} =
        Agent.start_link(fn ->
          # For testing we use a specific local clock
          clkinit = XestClock.local()
          clk = %{clkinit | local: clkinit.local |> XestClock.Clock.with_read([1, 2, 3, 4, 5])}
          #  and merge with another "remote" clock
          Map.merge(clk, XestClock.remote(:testremote, :nanosecond, [1, 2, 3, 4, 5]))
        end)

      ltick = fn ->
        Agent.get_and_update(
          clock_agent,
          fn %{local: local, testremote: remote} ->
            # Note : we update teh agent, by returning one tick from the stream,
            #                             and dropping it in the state.
            # With a function read() instead of a list, that drop is implicit,
            # and the state is the system clock tracking current time
            {
              %{
                local:
                  local
                  |> Stream.take(1)
                  |> Enum.into([]),
                testremote: remote.last
              },
              %{
                local:
                  local
                  |> Stream.drop(1),
                testremote: remote
              }
            }
          end
        )
      end

      rtick = fn ->
        Agent.get_and_update(
          clock_agent,
          fn %{local: local, testremote: remote} ->
            {
              %{
                local: local.last,
                testremote:
                  remote
                  |> Stream.take(1)
                  |> Enum.into([])
              },
              %{
                local: local,
                testremote:
                  remote
                  |> Stream.drop(1)
              }
            }
          end
        )
      end

      %{local_tick: ltick, remote_tick: rtick}
    end

    test "can get one local tick as a timestamp", %{local_tick: ltick, remote_tick: rtick} do
      %{local: ltick} = ltick.()
      assert ltick == [%XestClock.Clock.Timestamp{origin: :local, ts: 1, unit: :nanosecond}]
    end

    test "can output one remote tick as a timestamp", %{local_tick: ltick, remote_tick: rtick} do
      %{testremote: rtick} = rtick.()
      assert rtick == [%XestClock.Clock.Timestamp{origin: :testremote, ts: 1, unit: :nanosecond}]
    end

    #    test "can output one actual remote tick as a time"
    #    test "can output one simulated remote tick as a time"
  end
end

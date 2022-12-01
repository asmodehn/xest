defmodule XestClockTest do
  use ExUnit.Case
  doctest XestClock

  alias XestClock.Clock

  describe "XestClock" do
    test "local/0 builds a nanosecond clock with a local key" do
      clk = XestClock.local()
      assert %Clock{unit: :nanosecond} = clk.local
    end

    test "local/1 builds a clock with a local key" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clk = XestClock.local(unit)
        assert %Clock{unit: ^unit} = clk.local
      end
    end

    test "with_proxy/2 adds a proxy to the map with the origin key" do
      clk =
        XestClock.with_proxy(
          XestClock.local(),
          Clock.new(:testclock, :nanosecond, [1, 2, 3, 4])
        )

      assert %Clock{origin: :testclock, unit: :nanosecond, read: [1, 2, 3, 4]} ==
               clk.testclock.remote
    end
  end

  #  describe "XestClock inside a Process" do
  #    setup do
  #      {:ok, clock_agent} =
  #        Agent.start_link(fn ->
  #          # For testing we use a specific local clock
  #          clkinit = XestClock.local()
  #          clk = %{clkinit | local: clkinit.local |> Clock.with_read([1, 2, 3, 4, 5])}
  #          remote = Clock.new(:testremote, :nanosecond, [1, 2, 3, 4, 5])
  #          #  and add the proxy of another "remote" clock
  #          XestClock.with_proxy(clk, remote)
  #        end)
  #
  #      ltick = fn ->
  #        Agent.get_and_update(
  #          clock_agent,
  #          fn %{local: local, testremote: remote} ->
  #            {
  #              # Note : we update the agent, by returning one tick from the stream,
  #              #                             and dropping it in the state.
  #              %{
  #                local:
  #                  local
  #                  |> Stream.take(1)
  #                  |> Enum.into([]),
  #                testremote: remote.last
  #              },
  #
  #              # With a function read() instead of a list, that drop is implicit,
  #              # and the state is the system clock tracking current time
  #              %{
  #                local:
  #                  local
  #                  |> Stream.drop(1),
  #                testremote: remote
  #              }
  #            }
  #          end
  #        )
  #      end
  #
  #      rtick = fn ->
  #        Agent.get_and_update(
  #          clock_agent,
  #          fn %{local: local, testremote: remote} ->
  #            {
  #              %{
  #                local: local.last,
  #                testremote:
  #                  remote
  #                  |> Stream.take(1)
  #                  |> Enum.into([])
  #              },
  #              %{
  #                local: local,
  #                testremote:
  #                  remote
  #                  |> Stream.drop(1)
  #              }
  #            }
  #          end
  #        )
  #      end
  #
  #      %{local_tick: ltick, remote_tick: rtick}
  #    end
  #
  #    test "can get one local tick as a timestamp", %{local_tick: ltick, remote_tick: rtick} do
  #      %{local: ltick} = ltick.()
  #      assert ltick == [%Clock.Timestamp{origin: :local, ts: 1, unit: :nanosecond}]
  #    end
  #
  #    test "can output one remote tick as a timestamp", %{local_tick: ltick, remote_tick: rtick} do
  #      %{testremote: rtick} = rtick.()
  #      assert rtick == [%Clock.Timestamp{origin: :testremote, ts: 1, unit: :nanosecond}]
  #    end
  #  end

  #  describe "XestClock as a stream" do
  #    setup do
  #      # For testing we use a specific local clock
  #      clkinit = XestClock.local(:microsecond)
  #      clk = %{clkinit | local: clkinit.local |> Clock.with_read([1, 2, 3, 4, 5])}
  #      #  and merge with another "remote" clock
  #      %{clk: Map.merge(clk, XestClock.remote(:testremote, :millisecond, [11, 12, 13, 14, 15]))}
  #    end
  #
  #    @tag :try_me
  #    test "can compute local time as datetime", %{clk: clk} do
  #      # no offset needed since we dont use monotone time here
  #      offset = fn _unit -> 0 end
  #
  #      # epoch + 1 micro
  #      assert clk |> XestClock.to_datetime(:local, :local, offset) |> Enum.at(0) ==
  #               ~U[1970-01-01 00:00:00.000001Z]
  #
  #    end
  #
  #    test "can compute remote time as datetime", %{clk: clk} do
  #      # no offset needed since we dont use monotone time here
  #      offset = fn _unit -> 0 end
  #
  #      # epoch + 11 milli (still in micro -local- precision)
  #      assert clk
  #             |> XestClock.to_datetime(:testremote, :local, offset)
  #             |> Enum.at(0) ==
  #               ~U[1970-01-01 00:00:00.011000Z]
  #
  #    end
  #
  #    #    test "can output simulated remote time as datetime"
  #    #    test "can output simulated remote time as erl tuple"
  #  end
end

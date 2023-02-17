defmodule XestClockTest do
  use ExUnit.Case
  doctest XestClock

  import Hammox

  require ExampleServer

  describe "new/2" do
    test " returns streamclock if origin is System" do
      local = XestClock.new(:millisecond, System)

      XestClock.System.OriginalMock
      |> expect(:time_offset, 2, fn _ -> 0 end)
      |> expect(:monotonic_time, 2, fn :millisecond -> 1 end)

      assert local |> Enum.take(1) == [
               %XestClock.Time.Stamp{
                 origin: XestClock.System,
                 ts: %XestClock.Time.Value{unit: :millisecond, value: 1}
               }
             ]
    end

    test "returns streamclock with proxy if  a pid is provided" do
      # all test constant setup for recent linux nano second precision
      assert XestClock.System.Extra.native_time_unit() == :nanosecond

      example_srv = start_supervised!(ExampleServer, id: :example_sec)
      # TODO : child_spec for orign / pid ??? some better way ???
      clock = XestClock.new(:millisecond, ExampleServer, example_srv)

      # Preparing mocks for:
      #    - 4 ticks (exampleserver) + 3 corrections after sleep
      #    - 3 ticks (local)
      # In order to get 3 estimates.
      XestClock.System.OriginalMock
      # 7 times because sleep...
      |> expect(:monotonic_time, 13, fn
        # second to simulate the remote clock, required by the example genserver
        # TODO : make this a mock ? need a stable behaviour for the server...
        :second -> 42
        # for client stream in test process
        :millisecond -> 51_000
        # for proxy clock internal stream
        :nanosecond -> 51_000_000_000
      end)
      # 7 times because sleep...
      |> expect(:time_offset, 12, fn
        # for local proxy clock and client stream
        _ -> 0
      end)
      |> allow(self(), example_srv)

      XestClock.Process.OriginalMock
      # TODO : 2 instead of 1 ???
      |> expect(:sleep, 2, fn _ -> :ok end)

      # Note : the local timestamp calls these one time only.
      # other stream operators will rely on that timestamp

      # Since we have same source for local and remote
      assert clock |> Enum.take(3) == [
               %XestClock.Time.Estimate{
                 # error estimated from first
                 error: -9000,
                 unit: :millisecond,
                 # returned value from the remote server
                 value: 42000
               },
               %XestClock.Time.Estimate{
                 error: -9000,
                 unit: :millisecond,
                 value: 42000
               },
               %XestClock.Time.Estimate{
                 error: -9000,
                 unit: :millisecond,
                 value: 42000
               }
             ]

      stop_supervised!(:example_sec)
    end
  end
end

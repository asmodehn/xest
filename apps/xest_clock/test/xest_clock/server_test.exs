defmodule XestClock.ServerTest do
  # TMP to prevent errors given the stateful gen_server
  use ExUnit.Case, async: false
  doctest XestClock.Server

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  require ExampleServer

  describe "tick" do
    test " depends on unit on creation, it reached all the way to the callback" do
      # mocks expectations are needed since clock also tracks local time internally
      #      XestClock.System.ExtraMock
      #      |> expect(:native_time_unit, 4, fn -> :nanosecond end)
      # |> allow(self(), example_srv)

      for unit <- [:nanosecond, :microsecond, :millisecond, :second] do
        srv_id = String.to_atom("example_#{unit}")

        example_srv = start_supervised!({ExampleServer, unit}, id: srv_id)

        # Preparing mocks for 2 + 1 ticks...
        # This is used for local stamp -> only in ms
        XestClock.System.OriginalMock
        |> expect(:monotonic_time, 3, fn
          #          :second -> 42
          :millisecond -> 42_000
          #          :microsecond -> 42_000_000
          #          :nanosecond -> 42_000_000_000
          # default and parts per seconds
          pps -> 42 * pps
        end)
        |> expect(:time_offset, 3, fn :millisecond -> 0 end)
        |> allow(self(), example_srv)

        # Note : the local timestamp calls these one time only.
        # other stream operator will rely on that timestamp

        unit_pps = fn
          :second -> 1
          :millisecond -> 1_000
          :microsecond -> 1_000_000
          :nanosecond -> 1_000_000_000
        end

        assert ExampleServer.tick(example_srv) == {
                 %XestClock.Time.Stamp{
                   origin: ExampleServer,
                   ts: %XestClock.Time.Value{
                     value: 42 * unit_pps.(unit),
                     unit: unit
                   }
                 },
                 # Local stamp is always in millisecond (sleep pecision)
                 %XestClock.Stream.Timed.LocalStamp{
                   monotonic: %XestClock.Time.Value{unit: :millisecond, value: 42_000},
                   unit: :millisecond,
                   vm_offset: 0
                 },
                 %XestClock.Stream.Timed.LocalDelta{
                   offset: %XestClock.Time.Value{
                     unit: unit,
                     value: 0
                   },
                   skew: nil
                 }
               }

        XestClock.Process.OriginalMock
        # Note : since this test code will tick faster than the unit in this case,
        # we need to mock sleep.
        |> expect(:sleep, 1, fn _ -> :ok end)
        |> allow(self(), example_srv)

        # second tick
        assert ExampleServer.tick(example_srv) == {
                 %XestClock.Time.Stamp{
                   origin: ExampleServer,
                   ts: %XestClock.Time.Value{
                     value: 42 * unit_pps.(unit),
                     unit: unit
                   }
                 },
                 # Local stamp is always in millisecond (sleep pecision)
                 %XestClock.Stream.Timed.LocalStamp{
                   monotonic: %XestClock.Time.Value{unit: :millisecond, value: 42_000},
                   unit: :millisecond,
                   vm_offset: 0
                 },
                 %XestClock.Stream.Timed.LocalDelta{
                   offset: %XestClock.Time.Value{
                     unit: unit,
                     value: 0
                   },
                   # offset 0 : skew is 0.0 even if denominator is == 0 (linear map)
                   skew: 0.0
                 }
               }

        stop_supervised!(srv_id)
      end
    end
  end

  describe "monotonic_time" do
    test "returns a local estimation of the remote clock with 2 local calls only" do
      srv_id = String.to_atom("example_monotonic")

      example_srv = start_supervised!({ExampleServer, :second}, id: srv_id)

      # Preparing mocks for 2 + 1 ticks...
      # This is used for local stamp -> only in ms
      XestClock.System.OriginalMock
      |> expect(:monotonic_time, 2, fn
        :millisecond -> 51_000
      end)
      |> expect(:time_offset, 2, fn :millisecond -> 0 end)
      |> allow(self(), example_srv)

      # getting monotonic_time of the server gives us the value received from the remote clock
      assert ExampleServer.monotonic_time(example_srv, :millisecond) == 42_000
    end
  end
end

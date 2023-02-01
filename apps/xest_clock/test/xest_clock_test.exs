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
      |> expect(:monotonic_time, fn :millisecond -> 1 end)

      assert local |> Enum.take(1) == [
               %XestClock.Time.Stamp{
                 origin: XestClock.System,
                 ts: %XestClock.Time.Value{
                   value: 1,
                   offset: nil,
                   skew: nil,
                   unit: :millisecond
                 }
               }

               # TODO : localstamp instead ???
             ]
    end

    #    test "returns streamclock with proxy if origin is a pid" do
    #
    #      example_srv = start_supervised!({ExampleServer, :second}, id: :example_sec)
    #      # TODO : child_spec for orign / pid ???
    #      clock = XestClock.new(:millisecond, example_srv)
    #
    #      assert clock |> Enum.take(3) ==[ {
    #               %XestClock.Timestamp{
    #                 origin: ExampleServer,
    #                 ts: %XestClock.TimeValue{
    #                   monotonic: 42,
    #                   offset: nil,
    #                   skew: nil,
    #                   unit: :second
    #                 }
    #               },
    #               %XestClock.Stream.Timed.LocalStamp{
    #                 monotonic: %XestClock.TimeValue{
    #                   monotonic: 42,
    #                   offset: nil,
    #                   skew: nil,
    #                   unit: :nanosecond
    #                 },
    #                 unit: :nanosecond,
    #                 vm_offset: 0
    #               }
    #             }
    #             ]
    #
    #
    #      stop_supervised!(:example_sec)
    #
    #    end
  end
end

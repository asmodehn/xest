defmodule XestClock.StreamTest do
  # TMP to prevent errors given the stateful gen_server
  use ExUnit.Case
  doctest XestClock.Stream

  import Hammox

  alias XestClock.Stream

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "repeatedly_timed/1" do
    test " adds a local timestamp to the element" do
      native = XestClock.System.Extra.native_time_unit()
      # test constants calibrated for recent linux
      assert native == :nanosecond

      XestClock.System.OriginalMock
      # since we take mid time-of-flight, monotonic_time and time_offset are called a double number of times !
      |> expect(:monotonic_time, fn ^native -> 50_998_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 51_002_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 51_499_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 51_501_000_000 end)
      |> expect(:time_offset, 4, fn ^native -> -33_000_000 end)

      assert Stream.repeatedly_timed(fn -> 42 end)
             |> Enum.take(2) == [
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: 51_000_000_000,
                  unit: :nanosecond,
                  vm_offset: -33_000_000
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  # Note the rounding precision error...
                  monotonic: 51_500_000_000,
                  unit: :nanosecond,
                  vm_offset: -33_000_000
                }}
             ]
    end
  end

  describe "repeatedly_throttled/2" do
    test " allows the whole stream to be generated as usual, if the pulls are slow enough" do
      native = XestClock.System.Extra.native_time_unit()
      # test constants calibrated for recent linux
      assert native == :nanosecond

      XestClock.System.OriginalMock
      # we dont care about offset here
      |> expect(:time_offset, 10, fn _ -> 0 end)
      # each pull will take 1_500 ms but we need to duplicate each call
      # as one is timed measurement, and the other for the rate.
      # BUT since we take mid time-of-flight,
      # monotonic_time and time_offset are called a double number of times !

      |> expect(:monotonic_time, fn ^native -> 41_998_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 42_002_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 43_498_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 43_502_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 44_998_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 45_002_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 46_498_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 46_502_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 47_998_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 48_002_000_000 end)

      # minimal period of 100 millisecond.
      # the period of time checks is much slower (1.5 s)
      assert Stream.repeatedly_throttled(1000, fn -> 42 end)
             |> Enum.take(5) == [
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: 42_000_000_000,
                  unit: :nanosecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: 43_500_000_000,
                  unit: :nanosecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: 45_000_000_000,
                  unit: :nanosecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: 46_500_000_000,
                  unit: :nanosecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: 48_000_000_000,
                  unit: :nanosecond,
                  vm_offset: 0
                }}
             ]
    end

    test " throttles the stream generation, if the pulls are too fast" do
      native = XestClock.System.Extra.native_time_unit()
      # test constants calibrated for recent linux
      assert native == :nanosecond

      XestClock.System.OriginalMock
      # we dont care about offset here
      |> expect(:time_offset, 11, fn _ -> 0 end)
      # each pull will take 1_500 ms but we need to duplicate each call
      # as one is timed measurement, and the other for the rate.
      # BUT since we take mid time-of-flight,
      # monotonic_time and time_offset are called a double number of times !
      |> expect(:monotonic_time, fn ^native -> 41_998_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 42_002_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 43_498_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 43_502_000_000 end)

      # except for the third, which will be too fast, meaning the process will sleep...
      |> expect(:monotonic_time, fn ^native -> 44_000_000_000 end)
      # it will be called another time to correct the timestamp
      |> expect(:monotonic_time, fn ^native -> 44_999_000_000 end)
      # and once more after the request
      |> expect(:monotonic_time, fn ^native -> 45_001_000_000 end)
      # but then we revert to slow enough timing

      |> expect(:monotonic_time, fn ^native -> 46_498_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 46_502_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 47_998_000_000 end)
      |> expect(:monotonic_time, fn ^native -> 48_002_000_000 end)

      XestClock.Process.OriginalMock
      # sleep should be called with 0.5 ms = 500 us
      |> expect(:sleep, fn 502 -> :ok end)

      # limiter : ten per second
      assert Stream.repeatedly_throttled(1000, fn -> 42 end)
             |> Enum.take(5) == [
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: 42_000_000_000,
                  unit: :nanosecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: 43_500_000_000,
                  unit: :nanosecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: 45_000_000_000,
                  unit: :nanosecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: 46_500_000_000,
                  unit: :nanosecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: 48_000_000_000,
                  unit: :nanosecond,
                  vm_offset: 0
                }}
             ]
    end
  end
end

defmodule XestClock.StreamTest do
  # TMP to prevent errors given the stateful gen_server
  use ExUnit.Case
  doctest XestClock.Stream

  import Hammox

  alias XestClock.Stream

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "repeatedly_timed/2" do
    test " adds a local timestamp to the element" do
      XestClock.System.OriginalMock
      # since we take mid time-of-flight, monotonic_time and time_offset are called a double number of times !
      |> expect(:monotonic_time, fn :second -> 50_998 end)
      |> expect(:monotonic_time, fn :second -> 51_002 end)
      |> expect(:monotonic_time, fn :second -> 51_499 end)
      |> expect(:monotonic_time, fn :second -> 51_501 end)
      |> expect(:time_offset, 4, fn :second -> -33 end)

      assert Stream.repeatedly_timed(:second, fn -> 42 end)
             |> Enum.take(2) == [
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: %XestClock.Time.Value{unit: :second, value: 51_000},
                  unit: :second,
                  vm_offset: -33
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  # Note the rounding precision error...
                  monotonic: %XestClock.Time.Value{unit: :second, value: 51_501},
                  unit: :second,
                  vm_offset: -33
                }}
             ]
    end
  end

  describe "repeatedly_throttled/2" do
    test " allows the whole stream to be generated as usual, if the pulls are slow enough" do
      XestClock.System.OriginalMock
      # we dont care about offset here
      |> expect(:time_offset, 5, fn _ -> 0 end)
      # each pull will take 1_500 ms but we need to duplicate each call
      # as one is timed measurement, and the other for the rate.
      |> expect(:monotonic_time, fn :millisecond -> 42_000 end)
      |> expect(:monotonic_time, fn :millisecond -> 43_500 end)
      |> expect(:monotonic_time, fn :millisecond -> 45_000 end)
      |> expect(:monotonic_time, fn :millisecond -> 46_500 end)
      |> expect(:monotonic_time, fn :millisecond -> 48_000 end)

      # minimal period of 100 millisecond.
      # the period of time checks is much slower (1.5 s)
      assert Stream.repeatedly_throttled(1000, fn -> 42 end)
             |> Enum.take(5) == [
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: %XestClock.Time.Value{unit: :millisecond, value: 42000},
                  unit: :millisecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: %XestClock.Time.Value{unit: :millisecond, value: 43500},
                  unit: :millisecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: %XestClock.Time.Value{unit: :millisecond, value: 45000},
                  unit: :millisecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: %XestClock.Time.Value{unit: :millisecond, value: 46500},
                  unit: :millisecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: %XestClock.Time.Value{unit: :millisecond, value: 48000},
                  unit: :millisecond,
                  vm_offset: 0
                }}
             ]
    end

    test " throttles the stream generation, if the pulls are too fast" do
      XestClock.System.OriginalMock
      # we dont care about offset here
      |> expect(:time_offset, 6, fn _ -> 0 end)
      # each pull will take 1_500 ms but we need to duplicate each call
      # as one is timed measurement, and the other for the rate.
      |> expect(:monotonic_time, fn :millisecond -> 42_000 end)
      |> expect(:monotonic_time, fn :millisecond -> 43_500 end)
      # except for the third, which will be too fast, meaning the process will sleep...
      |> expect(:monotonic_time, fn :millisecond -> 44_000 end)
      # it will be called another time to correct the timestamp
      |> expect(:monotonic_time, fn :millisecond -> 44_999 end)
      # but then we revert to slow enough timing
      |> expect(:monotonic_time, fn :millisecond -> 46_500 end)
      |> expect(:monotonic_time, fn :millisecond -> 48_000 end)

      XestClock.Process.OriginalMock
      # sleep should be called with 0.5 ms = 500 us
      |> expect(:sleep, fn 500 -> :ok end)

      # limiter : ten per second
      assert Stream.repeatedly_throttled(1000, fn -> 42 end)
             |> Enum.take(5) == [
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: %XestClock.Time.Value{unit: :millisecond, value: 42000},
                  unit: :millisecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: %XestClock.Time.Value{unit: :millisecond, value: 43500},
                  unit: :millisecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: %XestClock.Time.Value{unit: :millisecond, value: 44999},
                  unit: :millisecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: %XestClock.Time.Value{unit: :millisecond, value: 46500},
                  unit: :millisecond,
                  vm_offset: 0
                }},
               {42,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: %XestClock.Time.Value{unit: :millisecond, value: 48000},
                  unit: :millisecond,
                  vm_offset: 0
                }}
             ]
    end
  end
end

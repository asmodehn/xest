defmodule XestClock.Stream.Timed.LocalStampTest do
  use ExUnit.Case
  doctest XestClock.Stream.Timed.LocalStamp

  import Hammox

  alias XestClock.Stream.Timed.LocalStamp

  describe "now/1" do
    test "creates a local timestamp with monotonic time and vm offset" do
      XestClock.System.OriginalMock
      |> expect(:monotonic_time, fn _unit -> 42 end)
      |> expect(:time_offset, fn _unit -> 33 end)

      assert LocalStamp.now(:millisecond) == %LocalStamp{
               unit: :millisecond,
               monotonic: 42,
               vm_offset: 33
             }
    end
  end

  describe "as_timevalue/1" do
    test "returns a local timevalue from a local timestamp" do
      XestClock.System.OriginalMock
      |> expect(:monotonic_time, fn _unit -> 42 end)
      |> expect(:time_offset, fn _unit -> 33 end)

      assert LocalStamp.now(:millisecond) |> LocalStamp.as_timevalue() ==
               %XestClock.Time.Value{unit: :millisecond, value: 42 + 33}
    end
  end

  describe "elapsed_since/2" do
    test "compute the difference beween two local timestamps to know the elapsed amount of time" do
      XestClock.System.OriginalMock
      |> expect(:monotonic_time, 2, fn _unit -> 42 end)
      |> expect(:time_offset, 2, fn _unit -> 33 end)

      previous = LocalStamp.now(:millisecond)
      now = LocalStamp.now(:millisecond)

      assert LocalStamp.elapsed_since(now, previous) ==
               %XestClock.Time.Value{unit: :millisecond, value: 0}
    end
  end

  describe "middle_stamp_estimate/2" do
    test "computes middle timestamp value between two timestamps" do
      XestClock.System.OriginalMock
      |> expect(:monotonic_time, fn :millisecond -> 42 end)
      |> expect(:time_offset, fn :millisecond -> 3 end)

      s1 = LocalStamp.now(:millisecond)

      XestClock.System.OriginalMock
      |> expect(:monotonic_time, fn :millisecond -> 51 end)
      |> expect(:time_offset, fn :millisecond -> 4 end)

      s2 = LocalStamp.now(:millisecond)

      assert LocalStamp.middle_stamp_estimate(s1, s2) == %LocalStamp{
               unit: :millisecond,
               # CAREFUL: we will lose precision here...
               monotonic: 46,
               vm_offset: 3
             }
    end

    test "computes middle time value between two timevalues, even in opposite order" do
      XestClock.System.OriginalMock
      |> expect(:monotonic_time, fn :millisecond -> 42 end)
      |> expect(:time_offset, fn :millisecond -> 3 end)

      s1 = LocalStamp.now(:millisecond)

      XestClock.System.OriginalMock
      |> expect(:monotonic_time, fn :millisecond -> 51 end)
      |> expect(:time_offset, fn :millisecond -> 4 end)

      s2 = LocalStamp.now(:millisecond)

      assert LocalStamp.middle_stamp_estimate(s2, s1) == %LocalStamp{
               unit: :millisecond,
               # CAREFUL: we will lose precision here...
               monotonic: 46,
               vm_offset: 3
             }
    end
  end

  describe "convert/2" do
  end

  # TODO : test protocol String.Chars
end

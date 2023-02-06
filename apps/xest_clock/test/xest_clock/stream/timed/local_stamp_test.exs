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
               monotonic: %XestClock.Time.Value{offset: nil, unit: :millisecond, value: 42},
               vm_offset: 33
             }
    end
  end

  describe "system_time/1" do
    test "returns a local system_time from a local timestamp" do
      XestClock.System.OriginalMock
      |> expect(:monotonic_time, fn _unit -> 42 end)
      |> expect(:time_offset, fn _unit -> 33 end)

      assert LocalStamp.now(:millisecond) |> LocalStamp.system_time() ==
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

  #  describe "with_previous/1" do
  #    test "adds offset to a local timestamp " do
  #      XestClock.System.OriginalMock
  #      |> expect(:monotonic_time, fn _unit -> 51 end)
  #      |> expect(:time_offset, fn _unit -> 31 end)
  #
  #      assert LocalStamp.now(:millisecond)
  #             |> LocalStamp.with_previous(%LocalStamp{
  #               unit: :millisecond,
  #               monotonic: %XestClock.Time.Value{offset: nil, unit: :millisecond, value: 42},
  #               vm_offset: 33
  #             }) ==
  #               %LocalStamp{
  #                 unit: :millisecond,
  #                 monotonic: %XestClock.Time.Value{offset: 9, unit: :millisecond, value: 51},
  #                 vm_offset: 31
  #               }
  #    end
  #  end

  # TODO : test protocol String.Chars
end

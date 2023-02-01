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

  describe "with_previous/1" do
    test "adds offset to a local timestamp " do
      XestClock.System.OriginalMock
      |> expect(:monotonic_time, fn _unit -> 51 end)
      |> expect(:time_offset, fn _unit -> 31 end)

      assert LocalStamp.now(:millisecond)
             |> LocalStamp.with_previous(%LocalStamp{
               unit: :millisecond,
               monotonic: %XestClock.Time.Value{offset: nil, unit: :millisecond, value: 42},
               vm_offset: 33
             }) ==
               %LocalStamp{
                 unit: :millisecond,
                 monotonic: %XestClock.Time.Value{offset: 9, unit: :millisecond, value: 51},
                 vm_offset: 31
               }
    end
  end

  # TODO : test protocol String.Chars
end

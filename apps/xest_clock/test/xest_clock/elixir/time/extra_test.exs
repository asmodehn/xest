defmodule XestClock.Time.ExtraTest do
  use ExUnit.Case
  doctest XestClock.Time.Extra

  import Hammox

  alias XestClock.Time.Extra

  describe "value/2" do
    test "return TimeValue" do
      assert Extra.value(:millisecond, 42) == %XestClock.Time.Value{
               value: 42,
               unit: :millisecond
             }
    end
  end

  describe "local_offset/1" do
    test "return a timevalue, representing the local vm_offset" do
      XestClock.System.OriginalMock
      |> expect(:time_offset, 5, fn
        :millisecond -> -42_000
      end)

      assert Extra.local_offset(:millisecond) == %XestClock.Time.Value{
               # TODO : rename this, maybe monotonic should be a property added to the struct ?
               value: -42_000,
               unit: :millisecond
             }
    end
  end

  describe "stamp/2" do
    test "with System returns a localstamp" do
      XestClock.System.OriginalMock
      |> expect(:time_offset, 5, fn
        :millisecond -> -42_000
      end)
      |> expect(:monotonic_time, 5, fn
        :millisecond -> 42_000
      end)

      assert Extra.stamp(System, :millisecond)

      %XestClock.Stream.Timed.LocalStamp{
        unit: :millisecond,
        monotonic: %XestClock.Time.Value{unit: :millisecond, value: 42_000},
        vm_offset: -42_000
      }
    end
  end

  describe "stamp/3" do
    test "returns a timestamp" do
      assert Extra.stamp(:somewhere, :millisecond, 123) == %XestClock.Time.Stamp{
               ts: %XestClock.Time.Value{unit: :millisecond, value: 123},
               origin: :somewhere
             }
    end
  end
end

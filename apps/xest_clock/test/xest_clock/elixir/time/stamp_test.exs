defmodule XestClock.Time.StampTest do
  use ExUnit.Case
  doctest XestClock.Time.Stamp

  alias XestClock.Time.Stamp

  describe "new/3" do
    test "builds a timestamp, containing a timevalue" do
      ts = Stamp.new(:test_origin, :millisecond, 123)

      assert ts == %Stamp{
               origin: :test_origin,
               ts: %XestClock.Time.Value{
                 value: 123,
                 unit: :millisecond
               }
             }
    end
  end

  describe "String.Chars protocol" do
    test "provide implementation of to_string" do
      ts = Stamp.new(:test_origin, :millisecond, 123)

      str = String.Chars.to_string(ts)

      assert str == "{test_origin: 123 ms}"
    end
  end
end

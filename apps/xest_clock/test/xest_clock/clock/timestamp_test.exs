defmodule XestClock.Clock.Timestamp.Test do
  use ExUnit.Case
  doctest XestClock.Clock.Timestamp

  alias XestClock.Clock.Timestamp

  describe "Clock.Timestamp" do
    test "new/3" do
      ts = Timestamp.new(:test_origin, :millisecond, 123)

      assert ts == %Timestamp{
               origin: :test_origin,
               unit: :millisecond,
               ts: 123
             }
    end

    test "diff/2 compute differences, convert units, and ignores origin" do
      tsa = Timestamp.new(:somewhere, :millisecond, 123)
      tsb = Timestamp.new(:anotherplace, :microsecond, 123)

      assert Timestamp.diff(tsa, tsb) == %Timestamp{
               origin: :somewhere,
               unit: :microsecond,
               ts: 123_000 - 123
             }

      assert Timestamp.diff(tsb, tsa) == %Timestamp{
               origin: :anotherplace,
               unit: :microsecond,
               ts: -123_000 + 123
             }
    end
  end
end

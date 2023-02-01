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
                 offset: nil,
                 unit: :millisecond
               }
             }
    end
  end

  describe "with_previous/2" do
    test "adds offset to the timevalue in the timestamp" do
      ts =
        Stamp.new(:test_origin, :millisecond, 123)
        |> Stamp.with_previous(Stamp.new(:test_origin, :millisecond, 12))

      assert ts == %Stamp{
               origin: :test_origin,
               ts: %XestClock.Time.Value{
                 value: 123,
                 offset: 111,
                 unit: :millisecond
               }
             }
    end
  end

  #    test "diff/2 compute differences, convert units, and ignores origin" do
  #      tsa = Timestamp.new(:somewhere, :millisecond, 123)
  #      tsb = Timestamp.new(:anotherplace, :microsecond, 123)
  #
  #      assert Timestamp.diff(tsa, tsb) == %Timestamp{
  #               origin: :somewhere,
  ##               unit: :microsecond,
  #               ts: 123_000 - 123
  #             }
  #
  #      assert Timestamp.diff(tsb, tsa) == %Timestamp{
  #               origin: :anotherplace,
  ##               unit: :microsecond,
  #               ts: -123_000 + 123
  #             }
  #    end
  #
  #    test "plus/2 compute sums, convert units, and ignores origin" do
  #      tsa = Timestamp.new(:somewhere, :millisecond, 123)
  #      tsb = Timestamp.new(:anotherplace, :microsecond, 123)
  #
  #      assert Timestamp.plus(tsa, tsb) == %Timestamp{
  #               origin: :somewhere,
  ##               unit: :microsecond,
  #               ts: 123_000 + 123
  #             }
  #
  #      assert Timestamp.plus(tsb, tsa) == %Timestamp{
  #               origin: :anotherplace,
  ##               unit: :microsecond,
  #               ts: 123_000 + 123
  #             }
  #    end

  describe "String.Chars protocol" do
    test "provide implementation of to_string" do
      ts = Stamp.new(:test_origin, :millisecond, 123)

      str = String.Chars.to_string(ts)

      assert str == "{test_origin: 123 ms}"
    end
  end
end

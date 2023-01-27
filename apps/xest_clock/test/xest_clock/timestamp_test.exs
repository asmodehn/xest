defmodule XestClock.Timestamp.Test do
  use ExUnit.Case
  doctest XestClock.Timestamp

  alias XestClock.Timestamp

  describe "Timestamp" do
    test "new/3" do
      ts = Timestamp.new(:test_origin, :millisecond, 123)

      assert ts == %Timestamp{
               origin: :test_origin,
               ts: %XestClock.TimeValue{
                 monotonic: 123,
                 offset: nil,
                 skew: nil,
                 unit: :millisecond
               }
             }
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

    test "implements String.Chars protocol to be able to output it directly" do
      ts = Timestamp.new(:test_origin, :millisecond, 123)

      str = String.Chars.to_string(ts)
      IO.puts(ts)
      assert str == "{test_origin: 123 ms}"
    end
  end
end

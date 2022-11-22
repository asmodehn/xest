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
  end
end

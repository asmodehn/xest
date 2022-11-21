defmodule XestClock.Clock.Timestamps.Test do
  use ExUnit.Case
  doctest XestClock.Clock.Timestamps

  alias XestClock.Clock.Timestamps

  describe "Clock.Timestamps" do
    test "new/3" do
      ts = Timestamps.new(:test_origin, :millisecond, [123, 456, 789])

      assert ts == %Timestamps{
               origin: :test_origin,
               unit: :millisecond,
               tss: [123, 456, 789]
             }
    end

    # TODO : test concat
  end
end

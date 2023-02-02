defmodule XestClock.Time.Estimate.Test do
  use ExUnit.Case
  doctest XestClock.Time.Estimate

  alias XestClock.Time.Estimate

  alias XestClock.Time
  alias XestClock.Stream.Timed

  describe "new/2" do
    test " accepts a time value and a local time delta" do
      assert Estimate.new(
               %Time.Value{
                 unit: :millisecond,
                 value: 42,
                 offset: nil
               },
               %Timed.LocalDelta{
                 offset: %Time.Value{
                   unit: :microsecond,
                   value: 51_000
                 },
                 # CAREFUL with float precision in tests...
                 skew: 0.75
               }
             ) == %Estimate{
               unit: :millisecond,
               value: 42 + 51,
               error: 51 * 0.25
             }
    end
  end
end

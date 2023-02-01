defmodule XestClock.TimeValue.Test do
  use ExUnit.Case
  doctest XestClock.TimeValue

  alias XestClock.TimeValue

  describe "TimeValue" do
    test "with_derivatives_from/2 computes offset but new skew without second offset provided" do
      assert XestClock.Time.Value.new(:millisecond, 42)
             |> TimeValue.with_derivatives_from(%XestClock.Time.Value{
               unit: :millisecond,
               value: 33
             }) ==
               %XestClock.Time.Value{
                 unit: :millisecond,
                 value: 42,
                 # 42 - 33
                 offset: 9,
                 skew: nil
               }
    end

    test "with_derivatives_from/2 computes offset and skew when a second offset is provided" do
      assert XestClock.Time.Value.new(:millisecond, 42)
             |> TimeValue.with_derivatives_from(%XestClock.Time.Value{
               unit: :millisecond,
               value: 33,
               offset: 7
             }) == %XestClock.Time.Value{
               unit: :millisecond,
               value: 42,
               # 42 - 33
               offset: 9,
               # 9 - 7
               skew: 2
             }
    end
  end
end

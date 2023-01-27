defmodule XestClock.TimeValue.Test do
  use ExUnit.Case
  doctest XestClock.TimeValue

  alias XestClock.TimeValue

  describe "TimeValue" do
    test "new/2 accepts a time_unit with an integer as monotonic value" do
      assert_raise(ArgumentError, fn ->
        TimeValue.new(:not_a_unit, 42)
      end)

      assert_raise(FunctionClauseError, fn ->
        TimeValue.new(:second, 23.45)
      end)

      assert TimeValue.new(:millisecond, 42) == %TimeValue{
               unit: :millisecond,
               monotonic: 42,
               offset: nil,
               skew: nil
             }
    end

    test "with_derivatives_from/2 computes offset but new skew without second offset provided" do
      assert TimeValue.new(:millisecond, 42)
             |> TimeValue.with_derivatives_from(%TimeValue{unit: :millisecond, monotonic: 33}) ==
               %TimeValue{
                 unit: :millisecond,
                 monotonic: 42,
                 # 42 - 33
                 offset: 9,
                 skew: nil
               }
    end

    test "with_derivatives_from/2 computes offset and skew when a second offset is provided" do
      assert TimeValue.new(:millisecond, 42)
             |> TimeValue.with_derivatives_from(%TimeValue{
               unit: :millisecond,
               monotonic: 33,
               offset: 7
             }) == %TimeValue{
               unit: :millisecond,
               monotonic: 42,
               # 42 - 33
               offset: 9,
               # 9 - 7
               skew: 2
             }
    end
  end
end

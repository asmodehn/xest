defmodule XestClock.Time.Value.Test do
  use ExUnit.Case
  doctest XestClock.Time.Value

  alias XestClock.Time.Value

  describe "TimeValue" do
    test "new/2 accepts a time_unit with an integer as monotonic value" do
      assert_raise(ArgumentError, fn ->
        Value.new(:not_a_unit, 42)
      end)

      assert_raise(FunctionClauseError, fn ->
        Value.new(:second, 23.45)
      end)

      assert Value.new(:millisecond, 42) == %Value{
               unit: :millisecond,
               value: 42,
               offset: nil,
               skew: nil
             }
    end
  end

  # TODO  test string.Chars protocol
  # TODO test inspect protocol
end

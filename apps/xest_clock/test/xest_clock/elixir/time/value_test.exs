defmodule XestClock.Time.Value.Test do
  use ExUnit.Case
  doctest XestClock.Time.Value

  alias XestClock.Time.Value

  describe "new/2" do
    test " accepts a time_unit with an integer as monotonic value" do
      assert_raise(ArgumentError, fn ->
        Value.new(:not_a_unit, 42)
      end)

      assert_raise(FunctionClauseError, fn ->
        Value.new(:second, 23.45)
      end)

      assert Value.new(:millisecond, 42) == %Value{
               unit: :millisecond,
               value: 42,
               offset: nil
             }
    end
  end

  describe "with_previous/2" do
    test " adds offset to existing value" do
      assert Value.new(:millisecond, 42)
             |> Value.with_previous(%Value{
               unit: :millisecond,
               value: 33
             }) ==
               %Value{
                 unit: :millisecond,
                 value: 42,
                 # 42 - 33
                 offset: 9
               }
    end
  end

  describe "convert/2" do
    test "converts timevalue with offset to a different time_unit" do
      v =
        Value.new(:millisecond, 42)
        |> Value.with_previous(%Value{
          unit: :millisecond,
          value: 33
        })

      assert Value.convert(v, :microsecond) ==
               %Value{
                 unit: :microsecond,
                 value: 42_000,
                 # 42000 - 33000
                 offset: 9_000
               }
    end
  end

  describe "diff/2" do
    test "computes difference in values between two timevalues" do
      v1 = Value.new(:millisecond, 42)

      v2 = %Value{
        unit: :millisecond,
        value: 33
      }

      assert Value.diff(v1, v2) == %Value{
               unit: :millisecond,
               value: 9
             }
    end
  end

  # TODO  test string.Chars protocol
  # TODO test inspect protocol
end

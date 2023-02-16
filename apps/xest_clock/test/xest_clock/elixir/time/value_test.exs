defmodule XestClock.Time.Value.Test do
  use ExUnit.Case
  doctest XestClock.Time.Value

  alias XestClock.Time.Value

  describe "new/2" do
    test " accepts a time_unit with an integer as value" do
      assert_raise(ArgumentError, fn ->
        Value.new(:not_a_unit, 42)
      end)

      assert_raise(FunctionClauseError, fn ->
        Value.new(:second, 23.45)
      end)

      assert Value.new(:millisecond, 42) == %Value{
               unit: :millisecond,
               value: 42
             }
    end

    test " accepts an integer as error" do
      assert Value.new(:millisecond, 42, 3) == %Value{
               unit: :millisecond,
               value: 42,
               error: 3
             }
    end
  end

  describe "convert/2" do
    test "converts timevalue to a different time_unit" do
      v = Value.new(:millisecond, 42)

      assert Value.convert(v, :microsecond) ==
               %Value{
                 unit: :microsecond,
                 value: 42_000
               }
    end

    test "also converts error to a different time_unit" do
      v = Value.new(:millisecond, 42, 3)

      assert Value.convert(v, :microsecond) ==
               %Value{
                 unit: :microsecond,
                 value: 42_000,
                 error: 3_000
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

    test "doesnt loose precision between two time values" do
      v1 = Value.new(:millisecond, 42)

      v2 = %Value{
        unit: :second,
        value: 33
      }

      assert Value.diff(v1, v2) == %Value{
               unit: :millisecond,
               value: -32_958
             }
    end

    test "compound the errors of the two timevalues" do
      v1 = Value.new(:millisecond, 42, 3)

      v2 = %Value{
        unit: :millisecond,
        value: 33,
        error: 5
      }

      assert Value.diff(v1, v2) == %Value{
               unit: :millisecond,
               value: 9,
               error: 8
             }
    end

    test "compound the errors of the two timevalues with different units" do
      v1 = Value.new(:millisecond, 42, 3)

      v2 = %Value{
        unit: :second,
        value: 33,
        error: 5
      }

      assert Value.diff(v1, v2) == %Value{
               unit: :millisecond,
               value: -32_958,
               error: 5_003
             }
    end
  end

  describe "sum/2" do
    test "computes sum in values between two timevalues" do
      v1 = Value.new(:millisecond, 42)

      v2 = %Value{
        unit: :millisecond,
        value: 33
      }

      assert Value.sum(v1, v2) == %Value{
               unit: :millisecond,
               value: 75
             }
    end

    test "doesnt loose precision between two time values" do
      v1 = Value.new(:millisecond, 42)

      v2 = %Value{
        unit: :second,
        value: 33
      }

      assert Value.sum(v1, v2) == %Value{
               unit: :millisecond,
               value: 33_042
             }
    end

    test "conserves errors between two time values" do
      v1 = Value.new(:millisecond, 42, 2)

      v2 = %Value{
        unit: :millisecond,
        value: 33,
        error: 3
      }

      assert Value.sum(v1, v2) == %Value{
               unit: :millisecond,
               value: 75,
               error: 5
             }
    end

    test "conserves errors between two time values with different units" do
      v1 = Value.new(:millisecond, 42, 2)

      v2 = %Value{
        unit: :second,
        value: 33,
        error: 3
      }

      assert Value.sum(v1, v2) == %Value{
               unit: :millisecond,
               value: 33_042,
               error: 3_002
             }
    end
  end

  describe "scale/2" do
  end

  describe "div/2" do
  end

  #
  #  describe "middle_estimate/2" do
  #    test "computes middle time value between two timevalues, with correct estimation error" do
  #      v1 = Value.new(:millisecond, 42)
  #
  #      v2 = %Value{
  #        unit: :millisecond,
  #        value: 33
  #      }
  #
  #      assert Value.middle_estimate(v1, v2) == %Value{
  #               unit: :millisecond,
  #               value: round(33 + (42 - 33) / 2),
  #                error: ceil((42 - 33) / 2)
  #             }
  #
  #    end
  #    test "computes middle time value between two timevalues, even in opposite order" do
  #      v1 = Value.new(:millisecond, 33)
  #
  #      v2 = %Value{
  #        unit: :millisecond,
  #        value: 42
  #      }
  #
  #      assert Value.middle_estimate(v1, v2) == %Value{
  #               unit: :millisecond,
  #               value: round(42 - (33 - 42) / 2),
  #                error: ceil((33 - 42) / 2)
  #             }
  #
  #    end
  #    test "computes middle time value, without forgetting existing errors" do
  #                  v1 = Value.new(:millisecond, 42, 2)
  #
  #      v2 = %Value{
  #        unit: :millisecond,
  #        value: 33,
  #      error: 3
  #      }
  #
  #      assert Value.middle_estimate(v1, v2) == %Value{
  #               unit: :millisecond,
  #               value: round(33 + (42 - 33) / 2),
  #                error: ceil((33 - 42) / 2) + 3 + 2  # error compounds
  #             }
  #
  #    end
  #
  #  end

  # TODO test stream()

  # TODO  test string.Chars protocol
  # TODO test inspect protocol
end

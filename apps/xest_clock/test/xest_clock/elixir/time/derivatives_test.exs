defmodule XestClock.Time.DerivativesTest do
  use ExUnit.Case
  doctest XestClock.Time.Derivatives

  alias XestClock.Time.Derivatives

  alias XestClock.Time
  alias XestClock.Stream.Timed

  describe "new/2" do
    test "builds a derivatives struct from a time value and a local timestamp" do
      assert Derivatives.new(
               %Time.Value{
                 unit: :millisecond,
                 value: 42,
                 error: 3
               },
               %Timed.LocalStamp{
                 unit: :millisecond,
                 monotonic: 51,
                 vm_offset: -33
               }
             ) == %Derivatives{
               unit: :millisecond,
               last_local: %Timed.LocalStamp{
                 unit: :millisecond,
                 monotonic: 51,
                 vm_offset: -33
               },
               prop: %Time.Value{
                 unit: :millisecond,
                 value: 42 - (51 - 33),
                 error: 3
               },
               derv: {0.0, 0.0},
               intg: {0.0, 0.0}
             }
    end
  end

  describe "new/3" do
    test "builds a derivative struct from time value, local timestamp, and the previous derivative struct" do
      previous = %Derivatives{
        unit: :millisecond,
        last_local: %Timed.LocalStamp{
          unit: :millisecond,
          # Note: no error in localstamp with local measurement.
          monotonic: 51,
          vm_offset: -33
        },
        prop: %Time.Value{
          unit: :millisecond,
          value: 42 - (51 - 33),
          error: 3
        },
        derv: {1.0, 0.0},
        intg: {0.0, 0.0}
      }

      new_local = %Timed.LocalStamp{
        unit: :millisecond,
        # +8
        monotonic: 59,
        vm_offset: -33
      }

      elapsed = Timed.LocalStamp.elapsed_since(new_local, previous.last_local)

      # we expect the difference of offset over the elapsed local time
      skew_val = (50 - (59 - 33) - previous.prop.value) / elapsed.value
      expected_skew = {skew_val, skew_val * 3 / (42 - (51 - 33))}

      # we expect the difference in skew, over the elapsed local time
      intg_val = (50 - (59 - 33) + previous.prop.value) * 0.5 * elapsed.value
      expected_intg = {intg_val, intg_val * 3 / (42 - (51 - 33))}

      assert Derivatives.new(
               %Time.Value{
                 unit: :millisecond,
                 # +8
                 value: 50,
                 error: 3
               },
               new_local,
               previous
             ) == %Derivatives{
               unit: :millisecond,
               last_local: %Timed.LocalStamp{
                 unit: :millisecond,
                 monotonic: 59,
                 vm_offset: -33
               },
               prop: %Time.Value{
                 unit: :millisecond,
                 value: 50 - (59 - 33),
                 # constant error -> no error in skew
                 error: 3
               },
               derv: expected_skew,
               intg: expected_intg
             }
    end
  end
end

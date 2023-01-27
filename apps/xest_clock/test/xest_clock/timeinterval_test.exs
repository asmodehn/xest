defmodule XestClock.Timeinterval.Test do
  use ExUnit.Case
  doctest XestClock.Timeinterval

  alias XestClock.TimeValue
  alias XestClock.Timeinterval

  describe "Clock.Timeinterval" do
    setup do
      tsb = %TimeValue{
        unit: :millisecond,
        monotonic: 12_345
      }

      tsa = %TimeValue{
        unit: :millisecond,
        monotonic: 12_346
      }

      %{before: tsb, after: tsa}
    end

    test "build/2 rejects timestamps with different units", %{before: tsb, after: tsa} do
      assert_raise(ArgumentError, fn ->
        Timeinterval.build(
          %TimeValue{
            unit: :microsecond,
            monotonic: 897_654
          },
          tsa
        )
      end)

      assert_raise(ArgumentError, fn ->
        Timeinterval.build(tsb, %TimeValue{
          unit: :microsecond,
          monotonic: 897_654
        })
      end)
    end

    test "build/2 accepts timestamps in order", %{before: tsb, after: tsa} do
      assert Timeinterval.build(tsb, tsa) == %Timeinterval{
               unit: :millisecond,
               interval: %Interval.Integer{
                 left: {:inclusive, 12_345},
                 right: {:exclusive, 12_346}
               }
             }
    end

    test "build/2 accepts timestamps in reverse order", %{before: tsb, after: tsa} do
      assert Timeinterval.build(tsa, tsb) == %Timeinterval{
               unit: :millisecond,
               interval: %Interval.Integer{
                 left: {:inclusive, 12_345},
                 right: {:exclusive, 12_346}
               }
             }
    end
  end
end

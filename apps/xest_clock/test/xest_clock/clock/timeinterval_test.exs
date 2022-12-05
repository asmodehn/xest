defmodule XestClock.Clock.Timeinterval.Test do
  use ExUnit.Case
  doctest XestClock.Clock.Timeinterval

  alias XestClock.Timestamp
  alias XestClock.Clock.Timeinterval

  describe "Clock.Timeinterval" do
    setup do
      tsb = %Timestamp{origin: :somewhere, unit: :millisecond, ts: 12345}
      tsa = %Timestamp{origin: :somewhere, unit: :millisecond, ts: 12346}
      %{before: tsb, after: tsa}
    end

    test "build/2 rejects timestamps with different origins", %{before: tsb, after: tsa} do
      assert_raise(ArgumentError, fn ->
        Timeinterval.build(
          %Timestamp{
            origin: :somewhere_else,
            unit: :millisecond,
            ts: 897_654
          },
          tsa
        )
      end)

      assert_raise(ArgumentError, fn ->
        Timeinterval.build(tsb, %Timestamp{
          origin: :somewhere_else,
          unit: :millisecond,
          ts: 897_654
        })
      end)
    end

    test "build/2 rejects timestamps with different units", %{before: tsb, after: tsa} do
      assert_raise(ArgumentError, fn ->
        Timeinterval.build(
          %Timestamp{
            origin: :somewhere_else,
            unit: :microsecond,
            ts: 897_654
          },
          tsa
        )
      end)

      assert_raise(ArgumentError, fn ->
        Timeinterval.build(tsb, %Timestamp{
          origin: :somewhere_else,
          unit: :microsecond,
          ts: 897_654
        })
      end)
    end

    test "build/2 accepts timestamps in order", %{before: tsb, after: tsa} do
      assert Timeinterval.build(tsb, tsa) == %Timeinterval{
               origin: :somewhere,
               unit: :millisecond,
               interval: %Interval.Integer{
                 left: {:inclusive, 12345},
                 right: {:exclusive, 12346}
               }
             }
    end

    test "build/2 accepts timestamps in reverse order", %{before: tsb, after: tsa} do
      assert Timeinterval.build(tsa, tsb) == %Timeinterval{
               origin: :somewhere,
               unit: :millisecond,
               interval: %Interval.Integer{
                 left: {:inclusive, 12345},
                 right: {:exclusive, 12346}
               }
             }
    end
  end
end

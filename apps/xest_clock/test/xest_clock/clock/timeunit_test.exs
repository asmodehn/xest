defmodule XestClock.Clock.Timeunit.Test do
  use ExUnit.Case
  doctest XestClock.Clock.Timeunit

  alias XestClock.Clock.Timeunit

  describe "Timeunit is ordered by precision" do
    test " second < millisecond < microsecond < nanosecond " do
      assert Timeunit.inf(:second, :millisecond)
      assert Timeunit.inf(:second, :microsecond)
      assert Timeunit.inf(:second, :nanosecond)
      assert Timeunit.inf(:millisecond, :microsecond)
      assert Timeunit.inf(:millisecond, :nanosecond)
      assert Timeunit.inf(:microsecond, :nanosecond)

      refute Timeunit.inf(:second, :second)
      refute Timeunit.inf(:millisecond, :millisecond)
      refute Timeunit.inf(:microsecond, :microsecond)
      refute Timeunit.inf(:nanosecond, :nanosecond)
    end

    test "nanosecond > microsecond > millisecond > second" do
      assert Timeunit.sup(:nanosecond, :microsecond)
      assert Timeunit.sup(:nanosecond, :millisecond)
      assert Timeunit.sup(:nanosecond, :second)
      assert Timeunit.sup(:microsecond, :millisecond)
      assert Timeunit.sup(:microsecond, :second)
      assert Timeunit.sup(:millisecond, :second)

      refute Timeunit.sup(:nanosecond, :nanosecond)
      refute Timeunit.sup(:microsecond, :microsecond)
      refute Timeunit.sup(:millisecond, :millisecond)
      refute Timeunit.sup(:second, :second)
    end
  end
end

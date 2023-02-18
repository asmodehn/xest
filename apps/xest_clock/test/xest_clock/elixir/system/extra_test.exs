defmodule XestClock.System.ExtraTest do
  use ExUnit.Case
  doctest XestClock.System.Extra

  describe "Timeunit is ordered by precision" do
    test " second < millisecond < microsecond < nanosecond " do
      assert XestClock.System.Extra.time_unit_inf(:second, :millisecond)
      assert XestClock.System.Extra.time_unit_inf(:second, :microsecond)
      assert XestClock.System.Extra.time_unit_inf(:second, :nanosecond)
      assert XestClock.System.Extra.time_unit_inf(:millisecond, :microsecond)
      assert XestClock.System.Extra.time_unit_inf(:millisecond, :nanosecond)
      assert XestClock.System.Extra.time_unit_inf(:microsecond, :nanosecond)

      refute XestClock.System.Extra.time_unit_inf(:second, :second)
      refute XestClock.System.Extra.time_unit_inf(:millisecond, :millisecond)
      refute XestClock.System.Extra.time_unit_inf(:microsecond, :microsecond)
      refute XestClock.System.Extra.time_unit_inf(:nanosecond, :nanosecond)
    end

    test "nanosecond > microsecond > millisecond > second" do
      assert XestClock.System.Extra.time_unit_sup(:nanosecond, :microsecond)
      assert XestClock.System.Extra.time_unit_sup(:nanosecond, :millisecond)
      assert XestClock.System.Extra.time_unit_sup(:nanosecond, :second)
      assert XestClock.System.Extra.time_unit_sup(:microsecond, :millisecond)
      assert XestClock.System.Extra.time_unit_sup(:microsecond, :second)
      assert XestClock.System.Extra.time_unit_sup(:millisecond, :second)

      refute XestClock.System.Extra.time_unit_sup(:nanosecond, :nanosecond)
      refute XestClock.System.Extra.time_unit_sup(:microsecond, :microsecond)
      refute XestClock.System.Extra.time_unit_sup(:millisecond, :millisecond)
      refute XestClock.System.Extra.time_unit_sup(:second, :second)
    end
  end
end

defmodule XestClockTest do
  use ExUnit.Case
  doctest XestClock

  describe "XestClock" do
    test "defaults to no remote and local naive utc_now closure" do
      clk = %XestClock{}
      assert clk.remotes == %{}
      assert clk.system_clock_closure == (&NaiveDateTime.utc_now/0)
    end

    test "accepts different system closures for tests" do
      clk = %XestClock{system_clock_closure: fn -> ~N[2010-04-17 14:00:00] end}
      assert clk.remotes == %{}
      assert clk.system_clock_closure.() == ~N[2010-04-17 14:00:00]
    end
  end

  describe "utc_now/1" do
    setup do
      clk = %XestClock{system_clock_closure: fn -> ~N[2010-04-17 14:00:00] end}
      %{clock: clk}
    end

    test "returns local now", %{clock: clk} do
      assert XestClock.utc_now(clk) == ~N[2010-04-17 14:00:00]
    end
  end

  describe "utc_now/2" do
    test "returns exchange clock"
  end
end

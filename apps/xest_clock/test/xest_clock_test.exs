defmodule XestClockTest do
  use ExUnit.Case
  doctest XestClock

  alias XestClock.Clock
  alias XestClock.Proxy
  alias XestClock.Monotone

  describe "XestClock" do
    test "local/0 builds a nanosecond clock with a local key" do
      clk = XestClock.local()
      assert %Clock{unit: :nanosecond} = clk.local
    end

    test "local/1 builds a clock with a local key" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clk = XestClock.local(unit)
        assert %Clock{unit: ^unit} = clk.local
      end
    end

    test "custom/3 builds a clock with a custom key that accepts enumerables" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clk = XestClock.custom(:testorigin, unit, [1, 2, 3, 4])
        assert %Clock{unit: ^unit} = clk.testorigin
      end
    end

    test "with_custom/4 adds a clock with a custom key that accepts enumerables" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clk =
          XestClock.local(unit)
          |> XestClock.with_custom(:testorigin, unit, [1, 2, 3, 4])

        assert %Clock{unit: ^unit} = clk.testorigin
        assert %Clock{unit: ^unit} = clk.local
      end
    end

    test "with_proxy/2 adds a proxy to the map with the origin key" do
      clk =
        XestClock.custom(:testref, :nanosecond, [0, 1, 2, 3])
        |> XestClock.with_proxy(
          Clock.new(:testclock, :nanosecond, [1, 2, 3, 4]),
          :testref
        )

      assert %Proxy{
               reference: clk.testref,
               offset: Clock.offset(clk.testref, Clock.new(:testclock, :nanosecond, [1, 2, 3, 4]))
             } == clk.testclock
    end
  end
end

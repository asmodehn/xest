defmodule XestClock.ClockTest do
  use ExUnit.Case
  doctest XestClock.Clock

  alias XestClock.StreamClock

  describe "XestClock" do
    test "local/0 builds a nanosecond clock with a local key" do
      clk = XestClock.Clock.local()
      assert %StreamClock{unit: :nanosecond} = clk.local
    end

    test "local/1 builds a clock with a local key" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clk = XestClock.Clock.local(unit)
        assert %StreamClock{unit: ^unit} = clk.local
      end
    end

    test "custom/3 builds a clock with a custom key that accepts enumerables" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clk = XestClock.Clock.custom(:testorigin, unit, [1, 2, 3, 4])
        assert %StreamClock{unit: ^unit} = clk.testorigin
      end
    end

    test "with_custom/4 adds a clock with a custom key that accepts enumerables" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clk =
          XestClock.Clock.local(unit)
          |> XestClock.Clock.with_custom(:testorigin, unit, [1, 2, 3, 4])

        assert %StreamClock{unit: ^unit} = clk.testorigin
        assert %StreamClock{unit: ^unit} = clk.local
      end
    end

    test "with_proxy/2 adds a proxy to the map with the origin key" do
      clk =
        XestClock.Clock.custom(:testref, :nanosecond, [0, 1, 2, 3])
        |> XestClock.Clock.with_proxy(
          StreamClock.new(:testclock, :nanosecond, [1, 2, 3, 4]),
          :testref
        )

      offset =
        StreamClock.offset(clk.testref, StreamClock.new(:testclock, :nanosecond, [1, 2, 3, 4]))

      assert %StreamClock{
               origin: :testclock,
               unit: :nanosecond,
               stream: [0, 1, 2, 3],
               offset: offset
             } == %{clk.testclock | stream: clk.testclock.stream |> Enum.to_list()}
    end
  end
end

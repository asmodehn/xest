defmodule XestClock.TimestampsTest do
  use ExUnit.Case
  doctest XestClock.Timestamps

  alias XestClock.Timestamps

  describe "Timestamps" do
    test "new/1 creates timestamps with a given unit" do
      ts = Timestamps.new(:millisecond)

      assert ts == %Timestamps{unit: :millisecond, timestamps: []}
    end

    test "new/1 raises when a non standard unit is passed" do
      assert_raise(ArgumentError, fn ->
        Timestamps.new(:something_strange)
      end)
    end

    test "new/1 raises when :native unit is passed, as this is ambiguous" do
      assert_raise(ArgumentError, fn ->
        Timestamps.new(:native)
      end)
    end
  end
end

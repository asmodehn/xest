defmodule XestClock.NewWrapper.DateTime.Test do
  use ExUnit.Case, async: true
  doctest XestClock.NewWrapper.DateTime

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "to_naive/1" do
    # TODO: pure -> use stub for tests
  end

  describe "from_unix" do
    # TODO: pure -> use stub for tests
  end

  describe "from_unix!" do
    # TODO: pure -> use stub for tests
  end

  describe "utc_now/1" do
    test "returns the current utc time matchin the System.monotonic_time plus System.time_offset" do
      # impure, relies on System.system_time.
      # -> use mock and expect
      XestClock.System.ExtraMock
      |> expect(:native_time_unit, 2, fn -> :millisecond end)

      XestClock.System.OriginalMock
      |> expect(:monotonic_time, 1, fn
        :millisecond -> 42_000
      end)
      |> expect(:time_offset, 1, fn
        :millisecond -> -42_000
      end)

      # System.system_time is 0
      # Meaning utc_now is EPOCH
      assert XestClock.NewWrapper.DateTime.utc_now() == ~U[1970-01-01 00:00:00.000Z]
    end
  end
end

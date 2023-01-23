defmodule XestClock.Process.Test do
  use ExUnit.Case, async: true
  doctest XestClock.Process

  import Hammox

  use Hammox.Protect, module: XestClock.Process, behaviour: XestClock.Process.OriginalBehaviour

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "XestClock.Process.sleep/1" do
    test "is a mockable wrapper around Elixir.Process.sleep/1" do
      XestClock.Process.OriginalMock
      |> expect(:sleep, 1, fn
        _timeout -> :ok
      end)

      # In this test we mock the original process, and test that whatever it returns is returned
      assert XestClock.Process.sleep(42) == :ok
    end
  end
end

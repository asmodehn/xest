defmodule XestClock.Clock.Test do
  use ExUnit.Case
  doctest XestClock.Clock

  describe "XestClock.Remote.Clock" do
    setup do
      s = Stream.iterate(0, &(&1 + 1))

      clock = XestClock.Clock.new(s, :millisecond)
      %{clock: clock}
    end

    test "new/2 creates a stream of results of the function passed in arguments",
         %{clock: clock} do
      assert clock |> Stream.take(5) |> Enum.to_list() == [0, 1, 2, 3, 4]
      #        assert clock.accumulator == Task
    end
  end
end

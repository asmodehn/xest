defmodule XestClock.Stream.Timed.Test do
  use ExUnit.Case
  doctest XestClock.Stream.Timed

  import Hammox

  alias XestClock.Stream.Timed

  describe "timed/2" do
    test "adds local timestamp to each element" do
      XestClock.System.OriginalMock
      # each pull will take 1_500 ms
      |> expect(:monotonic_time, fn :millisecond -> 330 end)
      |> expect(:time_offset, fn :millisecond -> 10 end)
      |> expect(:monotonic_time, fn :millisecond -> 420 end)
      |> expect(:time_offset, fn :millisecond -> 11 end)
      |> expect(:monotonic_time, fn :millisecond -> 510 end)
      |> expect(:time_offset, fn :millisecond -> 12 end)

      assert [1, 2, 3]
             |> Timed.timed(:millisecond)
             |> Enum.to_list() == [
               {1,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: %XestClock.Time.Value{
                    value: 330,
                    offset: nil,
                    unit: :millisecond
                  },
                  unit: :millisecond,
                  vm_offset: 10
                }},
               {2,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: %XestClock.Time.Value{
                    value: 420,
                    offset: 90,
                    unit: :millisecond
                  },
                  unit: :millisecond,
                  vm_offset: 11
                }},
               {3,
                %XestClock.Stream.Timed.LocalStamp{
                  # Note : constant offset give a skew of zero (no skew -> good clock)
                  monotonic: %XestClock.Time.Value{
                    value: 510,
                    offset: 90,
                    unit: :millisecond
                  },
                  unit: :millisecond,
                  vm_offset: 12
                }}
             ]
    end
  end

  describe "untimed/2" do
    test "removes localtimestamp from each element" do
      XestClock.System.OriginalMock
      # each pull will take 1_500 ms
      |> expect(:monotonic_time, fn :millisecond -> 330 end)
      |> expect(:time_offset, fn :millisecond -> 10 end)
      |> expect(:monotonic_time, fn :millisecond -> 420 end)
      |> expect(:time_offset, fn :millisecond -> 11 end)
      |> expect(:monotonic_time, fn :millisecond -> 510 end)
      |> expect(:time_offset, fn :millisecond -> 12 end)

      assert [1, 2, 3]
             |> Timed.timed(:millisecond)
             |> Timed.untimed()
             |> Enum.to_list() == [1, 2, 3]
    end
  end
end

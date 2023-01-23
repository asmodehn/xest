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
                  monotonic: 330,
                  unit: :millisecond,
                  vm_offset: 10
                }},
               {2,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: 420,
                  unit: :millisecond,
                  vm_offset: 11
                }},
               {3,
                %XestClock.Stream.Timed.LocalStamp{
                  monotonic: 510,
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

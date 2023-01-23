defmodule XestClock.Stream.Limiter.Test do
  use ExUnit.Case
  doctest XestClock.Stream.Limiter

  import Hammox

  alias XestClock.Stream.Limiter

  describe "limiter/2" do
    test " allows the whole stream to be processed, if the pulls are slow enough" do
      XestClock.System.OriginalMock
      # each pull will take 1_500 ms
      |> expect(:monotonic_time, fn :millisecond -> 42_000 end)
      |> expect(:monotonic_time, fn :millisecond -> 43_500 end)
      |> expect(:monotonic_time, fn :millisecond -> 45_000 end)
      |> expect(:monotonic_time, fn :millisecond -> 46_500 end)
      |> expect(:monotonic_time, fn :millisecond -> 48_000 end)

      # limiter 10 per second, the period of time checks is much slower (1.5 s)
      assert [1, 2, 3, 4, 5]
             |> Limiter.limiter(10)
             |> Enum.to_list() == [1, 2, 3, 4, 5]
    end

    test " prevents going too far upstream, if the pulls are too fast" do
      XestClock.System.OriginalMock
      # each pull will take 1_500 ms
      |> expect(:monotonic_time, fn :millisecond -> 42_000 end)
      |> expect(:monotonic_time, fn :millisecond -> 43_500 end)
      # except for the third, which will be too fast, meaning the process will sleep...
      |> expect(:monotonic_time, fn :millisecond -> 44_000 end)
      # but then we revert to slow enough timing
      |> expect(:monotonic_time, fn :millisecond -> 45_500 end)
      |> expect(:monotonic_time, fn :millisecond -> 47_000 end)

      XestClock.Process.OriginalMock
      # sleep should be called with 0.5 ms = 500 us
      |> expect(:sleep, fn 0.5 -> :ok end)

      # limiter : ten per second
      assert [1, 2, 3, 4, 5]
             |> Limiter.limiter(10)
             |> Enum.to_list() == [1, 2, 3, 4, 5]
    end
  end
end

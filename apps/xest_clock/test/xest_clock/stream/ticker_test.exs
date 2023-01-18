defmodule XestClock.Stream.TickerServerTest do
  # TMP to prevent errors given the stateful gen_server
  use ExUnit.Case, async: false
  doctest XestClock.Stream.Ticker

  alias XestClock.Stream.Ticker

  describe "Ticker" do
    setup [:test_stream]

    defp test_stream(%{usecase: usecase}) do
      case usecase do
        :const_fun ->
          %{test_stream: Stream.repeatedly(fn -> 42 end)}

        :list ->
          %{test_stream: [5, 4, 3, 2, 1]}

        :stream ->
          %{
            test_stream:
              Stream.unfold(5, fn
                0 -> nil
                n -> {n, n - 1}
              end)
          }

          # TODO move usecase to streamclock test
          #        :streamclock ->
          #          %{
          #            test_stream:
          #              StreamClock.new(
          #                :testclock,
          #                :millisecond,
          #                [1, 2, 3, 4, 5],
          #                10
          #              )
          #          }
      end
    end

    @tag usecase: :list
    test "with List, returns it on ticks(42)", %{test_stream: test_stream} do
      ticker = Ticker.new(test_stream)

      assert {[5, 4, 3, 2, 1], _continuation} = Ticker.next(42, ticker)
    end

    @tag usecase: :const_fun
    test "with constant function in a Stream return value on next(1, ticker)",
         %{test_stream: test_stream} do
      ticker = Ticker.new(test_stream)
      assert {[42], _continuation} = Ticker.next(1, ticker)
    end

    @tag usecase: :list
    test "with List return value on tick(<pid>)", %{test_stream: test_stream} do
      ticker = Ticker.new(test_stream)
      assert {[5, 4, 3, 2], new_ticker} = Ticker.next(4, ticker)

      assert {[1], last_ticker} = Ticker.next(1, new_ticker)

      assert {[], :done} = Ticker.next(1, last_ticker)
    end

    @tag usecase: :stream
    test "with Stream.unfold() return value on tick()", %{test_stream: test_stream} do
      ticker = Ticker.new(test_stream)

      assert {[5, 4, 3, 2], new_ticker} = Ticker.next(4, ticker)

      assert {[1], last_ticker} = Ticker.next(1, new_ticker)

      assert {[], :done} = Ticker.next(1, last_ticker)
    end

    #    @tag usecase: :streamclock
    #    test "with StreamClock return proper Timestamp on tick()", %{streamstpr: streamstpr} do
    #      _before = Process.info(streamstpr)
    #
    #      assert Ticker.tick(streamstpr) == %XestClock.Timestamp{
    #               origin: :testclock,
    #               ts: 11,
    #               unit: :millisecond
    #             }
    #
    #      _first = Process.info(streamstpr)
    #
    #      # Note the memory does NOT stay constant for a clockbecuase of extra operations.
    #      # Lets just hope garbage collection works with it as expected (TODO : long running perf test in livebook)
    #
    #      assert Ticker.tick(streamstpr) == %XestClock.Timestamp{
    #               origin: :testclock,
    #               ts: 12,
    #               unit: :millisecond
    #             }
    #
    #      _second = Process.info(streamstpr)
    #
    #      # Note the memory does NOT stay constant for a clockbecuase of extra operations.
    #      # Lets just hope garbage collection works with it as expected (TODO : long running perf test in livebook)
    #
    #      assert Ticker.tick(streamstpr) == %XestClock.Timestamp{
    #               origin: :testclock,
    #               ts: 13,
    #               unit: :millisecond
    #             }
    #
    #      assert Ticker.tick(streamstpr) == %XestClock.Timestamp{
    #               origin: :testclock,
    #               ts: 14,
    #               unit: :millisecond
    #             }
    #
    #      assert Ticker.tick(streamstpr) == %XestClock.Timestamp{
    #               origin: :testclock,
    #               ts: 15,
    #               unit: :millisecond
    #             }
    #
    #      # TODO : seems we should return the last one instead of nil ??
    #      assert Ticker.tick(streamstpr) == nil
    #      # Note : the Process is still there (in case more data gets written into the stream...)
    #    end
  end
end

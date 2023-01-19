defmodule XestClock.Stream.TickerTest do
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
  end

  describe "Ticker in StreamStepper" do
    setup [:test_stream, :stepper_setup]

    defp stepper_setup(%{test_stream: test_stream}) do
      # We use start_supervised! from ExUnit to manage gen_stage
      # and not with the gen_stage :link option
      streamstpr = start_supervised!({StreamStepper, test_stream})
      %{streamstpr: streamstpr}
    end

    @tag usecase: :list
    test "with List, returns it on ticks(<pid>, 42)", %{streamstpr: streamstpr} do
      before = Process.info(streamstpr)

      assert StreamStepper.ticks(streamstpr, 42) == [5, 4, 3, 2, 1]

      after_compute = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(before, after_compute) > 0
    end

    @tag usecase: :const_fun
    test "with constant function in a Stream return value on tick(<pid>)",
         %{streamstpr: streamstpr} do
      before = Process.info(streamstpr)
      current_value = StreamStepper.tick(streamstpr)
      after_compute = Process.info(streamstpr)

      assert current_value == 42

      # Memory stay constant
      assert assert_constant_memory_reductions(before, after_compute) > 0
    end

    # TODO factorize with test in streamclock_test
    defp assert_constant_memory_reductions(before_reductions, after_reductions) do
      assert before_reductions[:total_heap_size] == after_reductions[:total_heap_size]
      assert before_reductions[:heap_size] == after_reductions[:heap_size]
      assert before_reductions[:stack_size] == after_reductions[:stack_size]
      # but reductions were processed
      after_reductions[:reductions] - before_reductions[:reductions]
    end

    @tag usecase: :list
    test "with List return value on tick(<pid>)", %{streamstpr: streamstpr} do
      before = Process.info(streamstpr)

      assert StreamStepper.tick(streamstpr) == 5

      first = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(before, first) > 0

      assert StreamStepper.tick(streamstpr) == 4

      second = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(first, second) > 0

      assert StreamStepper.tick(streamstpr) == 3

      assert StreamStepper.tick(streamstpr) == 2

      assert StreamStepper.tick(streamstpr) == 1

      assert StreamStepper.tick(streamstpr) == nil
      # Note : the Process is still there (in case more data gets written into the stream...)
    end

    @tag usecase: :stream
    test "with Stream.unfold() return value on tick()", %{streamstpr: streamstpr} do
      before = Process.info(streamstpr)

      assert StreamStepper.tick(streamstpr) == 5

      first = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(before, first) > 0

      assert StreamStepper.tick(streamstpr) == 4

      second = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(first, second) > 0

      assert StreamStepper.tick(streamstpr) == 3

      assert StreamStepper.tick(streamstpr) == 2

      assert StreamStepper.tick(streamstpr) == 1

      assert StreamStepper.tick(streamstpr) == nil
      # Note : the Process is still there (in case more data gets written into the stream...)
    end
  end
end

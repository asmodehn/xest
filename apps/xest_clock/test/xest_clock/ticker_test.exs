defmodule XestClock.StreamStepper.Test do
  # TMP to prevent errors given the stateful gen_server
  use ExUnit.Case, async: false
  doctest XestClock.Ticker

  alias XestClock.Ticker
  alias XestClock.StreamClock

  describe "Ticker" do
    setup [:test_stream, :stepper_setup]

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

        :streamclock ->
          %{
            test_stream:
              StreamClock.new(
                :testclock,
                :millisecond,
                [1, 2, 3, 4, 5],
                10
              )
          }
      end
    end

    defp stepper_setup(%{test_stream: test_stream}) do
      # We use start_supervised! from ExUnit to manage gen_stage
      # and not with the gen_stage :link option
      streamstpr = start_supervised!({Ticker, test_stream})
      %{streamstpr: streamstpr}
    end

    @tag usecase: :list
    test "with List, returns it on ticks(<pid>, 42)", %{streamstpr: streamstpr} do
      before = Process.info(streamstpr)

      assert Ticker.ticks(streamstpr, 42) == [5, 4, 3, 2, 1]

      after_compute = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(before, after_compute) > 0
    end

    @tag usecase: :const_fun
    test "with constant function in a Stream return value on tick(<pid>)",
         %{streamstpr: streamstpr} do
      before = Process.info(streamstpr)
      current_value = Ticker.tick(streamstpr)
      after_compute = Process.info(streamstpr)

      assert current_value == 42

      # Memory stay constant
      assert assert_constant_memory_reductions(before, after_compute) > 0
    end

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

      assert Ticker.tick(streamstpr) == 5

      first = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(before, first) > 0

      assert Ticker.tick(streamstpr) == 4

      second = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(first, second) > 0

      assert Ticker.tick(streamstpr) == 3

      assert Ticker.tick(streamstpr) == 2

      assert Ticker.tick(streamstpr) == 1

      assert Ticker.tick(streamstpr) == nil
      # Note : the Process is still there (in case more data gets written into the stream...)
    end

    @tag usecase: :stream
    test "with Stream.unfold() return value on tick()", %{streamstpr: streamstpr} do
      before = Process.info(streamstpr)

      assert Ticker.tick(streamstpr) == 5

      first = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(before, first) > 0

      assert Ticker.tick(streamstpr) == 4

      second = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(first, second) > 0

      assert Ticker.tick(streamstpr) == 3

      assert Ticker.tick(streamstpr) == 2

      assert Ticker.tick(streamstpr) == 1

      assert Ticker.tick(streamstpr) == nil
      # Note : the Process is still there (in case more data gets written into the stream...)
    end

    @tag usecase: :streamclock
    test "with StreamClock return proper Timestamp on tick()", %{streamstpr: streamstpr} do
      _before = Process.info(streamstpr)

      assert Ticker.tick(streamstpr) == %XestClock.Timestamp{
               origin: :testclock,
               ts: 11,
               unit: :millisecond
             }

      _first = Process.info(streamstpr)

      # Note the memory does NOT stay constant for a clockbecuase of extra operations.
      # Lets just hope garbage collection works with it as expected (TODO : long running perf test in livebook)

      assert Ticker.tick(streamstpr) == %XestClock.Timestamp{
               origin: :testclock,
               ts: 12,
               unit: :millisecond
             }

      _second = Process.info(streamstpr)

      # Note the memory does NOT stay constant for a clockbecuase of extra operations.
      # Lets just hope garbage collection works with it as expected (TODO : long running perf test in livebook)

      assert Ticker.tick(streamstpr) == %XestClock.Timestamp{
               origin: :testclock,
               ts: 13,
               unit: :millisecond
             }

      assert Ticker.tick(streamstpr) == %XestClock.Timestamp{
               origin: :testclock,
               ts: 14,
               unit: :millisecond
             }

      assert Ticker.tick(streamstpr) == %XestClock.Timestamp{
               origin: :testclock,
               ts: 15,
               unit: :millisecond
             }

      # TODO : seems we should return the last one instead of nil ??
      assert Ticker.tick(streamstpr) == nil
      # Note : the Process is still there (in case more data gets written into the stream...)
    end
  end
end

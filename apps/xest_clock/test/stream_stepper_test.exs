defmodule XestClock.StreamStepper.Test do
  use ExUnit.Case
  doctest XestClock.StreamStepper

  alias XestClock.Monotone
  alias XestClock.StreamStepper

  describe "StreamStepper" do
    setup [:test_stream, :gen_stage_setup]

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

    defp gen_stage_setup(%{test_stream: test_stream}) do
      # We use start_supervised! from ExUnit to manage gen_stage
      # and not with the gen_stage :link option
      streamstpr = start_supervised!({StreamStepper, {test_stream, []}})
      %{streamstpr: streamstpr}
    end

    @tag usecase: :const_fun
    test "with constant function in a Stream return value on next()",
         %{streamstpr: streamstpr} do
      before = Process.info(streamstpr)
      current_value = StreamStepper.next(streamstpr)
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
    test "with List return value on next()",
         %{streamstpr: streamstpr} do
      before = Process.info(streamstpr)

      assert StreamStepper.next(streamstpr) == 5

      first = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(before, first) > 0

      assert StreamStepper.next(streamstpr) == 4

      second = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(first, second) > 0

      assert StreamStepper.next(streamstpr) == 3

      assert StreamStepper.next(streamstpr) == 2

      assert StreamStepper.next(streamstpr) == 1

      assert StreamStepper.next(streamstpr) == nil
      # Note : the Process is still there (in case more data gets written into the stream...)
    end

    @tag usecase: :stream
    test "with Stream.unfold() return value on next()",
         %{streamstpr: streamstpr} do
      before = Process.info(streamstpr)

      assert StreamStepper.next(streamstpr) == 5

      first = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(before, first) > 0

      assert StreamStepper.next(streamstpr) == 4

      second = Process.info(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(first, second) > 0

      assert StreamStepper.next(streamstpr) == 3

      assert StreamStepper.next(streamstpr) == 2

      assert StreamStepper.next(streamstpr) == 1

      assert StreamStepper.next(streamstpr) == nil
      # Note : the Process is still there (in case more data gets written into the stream...)
    end
  end
end

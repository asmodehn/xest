defmodule XestClock.Monotone.Test do
  use ExUnit.Case
  doctest XestClock.Monotone

  alias XestClock.Monotone

  alias XestClock.StreamStepper

  describe "Monotone" do
    test "increasing/1 ensure the enumerable is monotonically increasing" do
      enum = [1, 2, 3, 5, 4, 6]

      assert Monotone.increasing(enum) |> Enum.to_list() == [1, 2, 3, 5, 5, 6]
    end

    test "decreasing/1 ensure the enumerable is monotonically decreasing" do
      enum = [6, 5, 3, 4, 2, 1]

      assert Monotone.decreasing(enum) |> Enum.to_list() == [6, 5, 3, 3, 2, 1]
    end

    test "strict/2 with :asc ensure the enumerable is stictly monotonically increasing" do
      enum = [1, 2, 3, 5, 4, 6]

      assert Monotone.strictly(enum, :asc) |> Enum.to_list() == [1, 2, 3, 5, 6]
    end

    test "strict/2 with :desc ensure the enumerable is stictly monotonically decreasing" do
      enum = [6, 5, 3, 4, 2, 1]

      assert Monotone.strictly(enum, :desc) |> Enum.to_list() == [6, 5, 3, 2, 1]
    end
  end

  defp assert_constant_memory_reductions(before_reductions, after_reductions) do
    assert before_reductions[:total_heap_size] == after_reductions[:total_heap_size]
    # IO.inspect after_reductions[:total_heap_size]
    assert before_reductions[:heap_size] == after_reductions[:heap_size]
    # IO.inspect after_reductions[:heap_size]
    assert before_reductions[:stack_size] == after_reductions[:stack_size]
    # but reductions were processed
    after_reductions[:reductions] - before_reductions[:reductions]
  end

  defp process_info_gc(pid) do
    # synchronously forces garbage collect, before collecting process info
    :erlang.garbage_collect(pid)
    Process.info(pid)
  end

  describe "Monotone.strictly increasing in StreamStepper" do
    setup do
      # We use start_supervised! from ExUnit to manage gen_stage
      # and not with the gen_stage :link option
      streamstpr =
        start_supervised!({StreamStepper, {Monotone.strictly([1, 2, 3, 5, 4, 6], :asc), []}})

      %{streamstpr: streamstpr}
    end

    test "return value on next() without using extra memory",
         %{streamstpr: streamstpr} do
      _before = process_info_gc(streamstpr)

      assert StreamStepper.next(streamstpr) == 1

      first = process_info_gc(streamstpr)

      # Note: Used memory increased at the start of the stream
      # assert assert_constant_memory_reductions(before, first) > 0
      # But we expect it to remain constant for later operations
      # since uniq_by is used only for the last element

      assert StreamStepper.next(streamstpr) == 2

      second = process_info_gc(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(first, second) > 0

      assert StreamStepper.next(streamstpr) == 3

      third = process_info_gc(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(second, third) > 0

      assert StreamStepper.next(streamstpr) == 5

      fourth = process_info_gc(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(third, fourth) > 0

      # Note 4 is skipped entirely
      assert StreamStepper.next(streamstpr) == 6

      fifth = process_info_gc(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(fourth, fifth) > 0

      assert StreamStepper.next(streamstpr) == nil
      # Note : the Process is still there (in case more data gets written into the stream...)

      sixth = process_info_gc(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(fifth, sixth) > 0
    end
  end

  describe "Monotone.strictly decreasing in StreamStepper" do
    setup do
      # We use start_supervised! from ExUnit to manage gen_stage
      # and not with the gen_stage :link option
      streamstpr =
        start_supervised!({StreamStepper, {Monotone.strictly([6, 5, 3, 4, 2, 1], :desc), []}})

      %{streamstpr: streamstpr}
    end

    test "return value on next() without using extra memory",
         %{streamstpr: streamstpr} do
      _before = process_info_gc(streamstpr)

      assert StreamStepper.next(streamstpr) == 6

      first = process_info_gc(streamstpr)

      # Note: Used memory increased at the start of the stream
      # assert assert_constant_memory_reductions(before, first) > 0
      # But we expect it to remain constant for later operations
      # since uniq_by is used only for the last element

      assert StreamStepper.next(streamstpr) == 5

      second = process_info_gc(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(first, second) > 0

      assert StreamStepper.next(streamstpr) == 3

      third = process_info_gc(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(second, third) > 0

      # Note 2 is skipped entirely
      assert StreamStepper.next(streamstpr) == 2

      fourth = process_info_gc(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(third, fourth) > 0

      assert StreamStepper.next(streamstpr) == 1

      fifth = process_info_gc(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(fourth, fifth) > 0

      assert StreamStepper.next(streamstpr) == nil
      # Note : the Process is still there (in case more data gets written into the stream...)

      sixth = process_info_gc(streamstpr)

      # Memory stay constant
      assert assert_constant_memory_reductions(fifth, sixth) > 0
    end
  end
end

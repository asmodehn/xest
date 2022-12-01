defmodule XestClock.CheckServer.Test do
  use ExUnit.Case
  doctest XestClock.CheckServer

  alias XestClock.Monotone
  alias XestClock.CheckServer

  describe "CheckServer" do
    setup do
      checksrv = start_supervised!({CheckServer, fn -> 42 end})
      %{checksrv: checksrv}
    end

    test "next generates value",
         %{checksrv: checksrv} do
      current_value = CheckServer.next(checksrv)

      assert current_value == 42
    end

    test "info reply with the memory used. It stays constant when generator is a constant function",
         %{checksrv: checksrv} do
      before = CheckServer.info(checksrv)

      CheckServer.next(checksrv)

      first = CheckServer.info(checksrv)

      # Memory stay constant
      assert first[:total_heap_size] == before[:total_heap_size]
      assert first[:heap_size] == before[:heap_size]
      assert first[:stack_size] == before[:stack_size]
      # but reductions were processed
      assert first[:reductions] != before[:reductions]

      CheckServer.next(checksrv)

      second = CheckServer.info(checksrv)

      # Memory stay constant
      assert first[:total_heap_size] == second[:total_heap_size]
      assert first[:heap_size] == second[:heap_size]
      assert first[:stack_size] == second[:stack_size]
      # but reductions were processed
      assert first[:reductions] != second[:reductions]
    end
  end
end

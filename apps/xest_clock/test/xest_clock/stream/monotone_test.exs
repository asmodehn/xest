defmodule XestClock.Stream.Monotone.Test do
  use ExUnit.Case
  doctest XestClock.Stream.Monotone

  alias XestClock.Stream.Monotone

  describe "Monotone on immutable enums" do
    test "increasing/1 is monotonically increasing" do
      enum = [1, 2, 3, 5, 4, 6]

      assert Monotone.increasing(enum) |> Enum.to_list() == [1, 2, 3, 5, 5, 6]
    end

    test "decreasing/1 is monotonically decreasing" do
      enum = [6, 5, 3, 4, 2, 1]

      assert Monotone.decreasing(enum) |> Enum.to_list() == [6, 5, 3, 3, 2, 1]
    end

    test "increasing/1 with Stream.dedup/1 is stictly monotonically increasing" do
      enum = [1, 2, 3, 5, 4, 6]

      assert Monotone.increasing(enum) |> Stream.dedup() |> Enum.to_list() == [1, 2, 3, 5, 6]
    end

    test "decreasing/1 with Stream.dedup/1  is stictly monotonically decreasing" do
      enum = [6, 5, 3, 4, 2, 1]

      assert Monotone.decreasing(enum) |> Stream.dedup() |> Enum.to_list() == [6, 5, 3, 2, 1]
    end

    test "offset/2 can apply an offset to the enum" do
      enum = [1, 2, 3, 5, 4]

      # offset doesnt enforce monotonicity
      assert Monotone.offset(enum, 10) |> Enum.to_list() ==
               [
                 11,
                 12,
                 13,
                 15,
                 14
               ]

      # but offset preserves monotonicity.

      assert Monotone.increasing(enum) |> Stream.dedup() |> Monotone.offset(10) |> Enum.to_list() ==
               [
                 11,
                 12,
                 13,
                 15
               ]
    end
  end

  describe "Monotone on stateful resources" do
    setup %{enum: enum} do
      #  A simple test ticker agent, that ticks everytime it is called
      {:ok, clock_agent} = start_supervised({Agent, fn -> enum end})

      ticker = fn ->
        Agent.get_and_update(
          clock_agent,
          fn
            # this is needed only if stream wants more elements than expected
            #            [] -> {nil, []}  commented to trigger error instead of infinite loop...
            [h | t] -> {h, t}
          end
        )
      end

      %{source: ticker}
    end

    @tag enum: [1, 2, 3, 5, 4, 6]
    test "increasing/1 doesnt consume elements", %{source: source} do
      assert Stream.repeatedly(source)
             |> Monotone.increasing()
             |> Enum.take(6) == [1, 2, 3, 5, 5, 6]
    end

    @tag enum: [6, 5, 3, 4, 2, 1]
    test "decreasing/1 doesnt consume elements", %{source: source} do
      assert Stream.repeatedly(source)
             |> Monotone.decreasing()
             |> Enum.take(6) == [6, 5, 3, 3, 2, 1]
    end

    @tag enum: [1, 2, 3, 5, 4, 6]
    test "increasing/1 with Stream.dedup/1 doesnt consume elements", %{source: source} do
      assert Stream.repeatedly(source)
             |> Monotone.increasing()
             |> Stream.dedup()
             |> Enum.take(5) == [1, 2, 3, 5, 6]
    end

    @tag enum: [6, 5, 3, 4, 2, 1]
    test "decreasing/1 with Stream.dedup/1 doesnt consume elements", %{source: source} do
      assert Stream.repeatedly(source)
             |> Monotone.decreasing()
             |> Stream.dedup()
             |> Enum.take(5) == [6, 5, 3, 2, 1]
    end
  end
end

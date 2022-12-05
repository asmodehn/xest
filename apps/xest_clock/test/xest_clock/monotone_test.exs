defmodule XestClock.Monotone.Test do
  use ExUnit.Case
  doctest XestClock.Monotone

  alias XestClock.Monotone

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
end

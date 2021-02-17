defmodule Xest.Test do
  use ExUnit.Case, async: true

  require Xest

  test "the answer" do
    assert Xest.answer() == 42
  end
end

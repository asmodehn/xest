defmodule Xest.TUITest do
  use ExUnit.Case
  doctest Xest.TUI

  test "greets the world" do
    assert Xest.TUI.hello() == :world
  end
end

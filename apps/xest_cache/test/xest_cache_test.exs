defmodule XestCacheTest do
  use ExUnit.Case

  require XestCache.ExampleCache
  doctest XestCache

  test "greets the world" do
    assert XestCache.hello() == :world
  end
end

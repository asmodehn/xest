defmodule XestCache.ExampleCache do
  use XestCache.Decorators

  @decorate cacheable(cache: XestCache.Nebulex, key: some_value)
  def my_fun_cached_with_nebulex(some_value) do
    some_value + 9
  end
end

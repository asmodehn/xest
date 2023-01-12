defmodule XestCache.Decorators do
  @moduledoc false

  use Decorator.Define, cacheable: 1

  require Nebulex.Caching

  @doc """
  A decorator to specify a function to be cached, following the read-through pattern
    cf. Nebulex.

  Note this is a macro. In case of a doubt, consult the Nebulex source or the decorators source.

  ## Examples

      # Cache itself is state and writing to it is a side-effect. We need to clean it before any test.
      # All doctests here are then run in sequence to prevent interaction with other tests.

      iex> XestCache.Nebulex.delete_all()
      iex(1)> XestCache.Nebulex.all()
      []
      iex(2)> XestCache.ExampleCache.my_fun_cached_with_nebulex(33)
      42
      iex(3)> XestCache.Nebulex.all(nil, return: {:key, :value})
      [{33, 42}]

  """
  def cacheable(attrs, block, context) do
    # delegate to nebulex decorator for now
    Nebulex.Caching.cacheable(attrs, block, context)
  end
end

defmodule XestClock.Stream.Monotone do
  @moduledoc """
    this module only deals with monotone enumerables.

  increasing and decreasing, just like for time warping and monotone time,
  can return the same value multiple times...

  However there is also the stricly function that will skip duplicated values, therefore
  enforcing the stream to be strictly monotonous.

  This means the elements of the stream must be comparable with >= <= and ==
  """

  @doc """
  A Monotonously increasing stream. Replace values that would invalidate the monotonicity
  with a duplicate of the previous value.
  Use Stream.dedup/1 if you want unique values, ie. a strictly monotonous stream.

  iex> m = XestClock.Stream.Monotone.increasing([1,3,2,5,4])
  iex(1)> Enum.to_list(m)
  [1,3,3,5,5]
  iex(2)> m |> Stream.dedup() |> Enum.to_list()
  [1,3,5]
  """
  @spec increasing(Enumerable.t()) :: Enumerable.t()
  def increasing(enum) do
    Stream.transform(enum, nil, fn
      i, nil -> {[i], i}
      i, acc -> if acc <= i, do: {[i], i}, else: {[acc], acc}
    end)
  end

  @doc """
  A Monotonously decreasing stream. Replace values that would invalidate the monotonicity
  with a duplicate of the previous value.
  Use Stream.dedup/1 if you want unique value, ie. a strictly monotonous stream.

  iex> m = XestClock.Stream.Monotone.decreasing([4,5,2,3,1])
  iex(1)> Enum.to_list(m)
  [4,4,2,2,1]
  iex(2)> m |> Stream.dedup() |> Enum.to_list()
  [4,2,1]
  """
  @spec decreasing(Enumerable.t()) :: Enumerable.t()
  def decreasing(enum) do
    Stream.transform(enum, nil, fn
      i, nil -> {[i], i}
      i, acc -> if acc >= i, do: {[i], i}, else: {[acc], acc}
    end)
  end

  # TODO : strict via unique_integer:
  # Time = erlang:monotonic_time(),
  # UMI = erlang:unique_integer([monotonic]),
  # EventTag = {Time, UMI}

  @doc """
  offset requires the elements to support the + operator with the offset value.
    It doesn't enforce monotonicity, but will preserve it, by construction.
  """
  def offset(enum, offset) do
    enum
    |> Stream.map(fn x -> x + offset end)
  end

  # TODO : linear map ! a * x + b with a and b monotonous will conserve monotonicity
  # a is the skew of the clock... CAREFUL : this might be linked with the time_unit concept...
  # or maybe not since a 1000 *  and a skew of 1.0001 *  are quite different in nature...
  # def skew(enum, skew) do end
end

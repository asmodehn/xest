defmodule XestClock.Monotone do
  @docmodule """
    this module only deals with monotone enumerables.

  increasing and decreasing, just like for time warping and monotone time,
  can return the same value multiple times...

  However there is also the stricly function that will skip duplicated values, therefore
  enforcing the stream to be strictly monotonous.

  This means the elements of the stream must be comparable with >= <= and ==
  """

  @spec increasing(Enumerable.t()) :: Enumerable.t()
  def increasing(enum) do
    Stream.transform(enum, nil, fn
      i, nil -> {[i], i}
      i, acc -> if acc <= i, do: {[i], i}, else: {[acc], acc}
    end)
  end

  @spec decreasing(Enumerable.t()) :: Enumerable.t()
  def decreasing(enum) do
    Stream.transform(enum, nil, fn
      i, nil -> {[i], i}
      i, acc -> if acc >= i, do: {[i], i}, else: {[acc], acc}
    end)
  end

  @spec strictly(Enumerable.t(), atom) :: Enumerable.t()
  def strictly(enum, :asc) do
    enum
    |> increasing
    # since we are working with integers,
    |> Stream.dedup()

    # this will eliminate values that pass the increasing test because they are equal
  end

  def strictly(enum, :desc) do
    enum
    |> decreasing
    # since we are working with integers,
    |> Stream.dedup()

    # this will eliminate values that pass the decreasing test because they are equal
  end

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
  # def skew(enum, skew) do end
end

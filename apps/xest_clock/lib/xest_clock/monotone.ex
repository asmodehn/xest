defmodule XestClock.Monotone do
  @docmodule """
    this module only deals with monotone enumerables.

  Just like for time warping and monotone time,
  it can return the same value multiple times...
  """

  require XestClock.Monotone.Reducers, as: Reducers

  @spec increasing(Enumerable.t()) :: Enumerable.t()
  def increasing(enum) do
    Stream.transform(enum, enum |> Enum.at(0), fn i, acc ->
      if acc <= i, do: {[i], i}, else: {[acc], acc}
    end)
  end

  @spec decreasing(Enumerable.t()) :: Enumerable.t()
  def decreasing(enum) do
    Stream.transform(enum, enum |> Enum.at(0), fn i, acc ->
      if acc >= i, do: {[i], i}, else: {[acc], acc}
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
end

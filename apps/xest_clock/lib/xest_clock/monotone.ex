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

  ## Macros from Elixir Stream
  defmacrop skip(acc) do
    {:cont, acc}
  end

  defmacrop next(fun, entry, acc) do
    quote(do: unquote(fun).(unquote(entry), unquote(acc)))
  end

  defmacrop acc(head, state, tail) do
    quote(do: [unquote(head), unquote(state) | unquote(tail)])
  end

  defmacrop next_with_acc(fun, entry, head, state, tail) do
    quote do
      {reason, [head | tail]} = unquote(fun).(unquote(entry), [unquote(head) | unquote(tail)])
      {reason, [head, unquote(state) | tail]}
    end
  end

  @spec uniq_by_once(Enumerable.t(), (any -> term)) :: Enumerable.t()
  def uniq_by_once(enum, fun) when is_function(fun, 1) do
    lazy(enum, %{}, fn f1 -> Reducers.uniq_by_once(fun, f1) end)
  end

  @spec strictly(Enumerable.t(), atom) :: Enumerable.t()
  def strictly(enum, :asc) do
    enum
    |> increasing
    |> uniq_by_once(fn x -> x end)
  end

  def strictly(enum, :desc) do
    enum
    |> decreasing
    |> uniq_by_once(fn x -> x end)
  end

  ## Helper from Elixir Stream
  @compile {:inline, lazy: 2, lazy: 3, lazy: 4}

  defp lazy(%Stream{done: nil, funs: funs} = lazy, fun), do: %{lazy | funs: [fun | funs]}
  defp lazy(enum, fun), do: %Stream{enum: enum, funs: [fun]}

  defp lazy(%Stream{done: nil, funs: funs, accs: accs} = lazy, acc, fun),
    do: %{lazy | funs: [fun | funs], accs: [acc | accs]}

  defp lazy(enum, acc, fun), do: %Stream{enum: enum, funs: [fun], accs: [acc]}

  defp lazy(%Stream{done: nil, funs: funs, accs: accs} = lazy, acc, fun, done),
    do: %{lazy | funs: [fun | funs], accs: [acc | accs], done: done}

  defp lazy(enum, acc, fun, done), do: %Stream{enum: enum, funs: [fun], accs: [acc], done: done}
end

defmodule XestClock.Stream.Ticker do
  @doc """
  Builds a ticker from a stream.
  Meaning calling next() on it will return n elements at a time.
  """
  @spec new(Enumerable.t()) :: Enumerable.continuation()
  def new(stream) do
    &Enumerable.reduce(stream, &1, fn
      x, {acc, 1} -> {:suspend, {[x | acc], 0}}
      x, {acc, counter} -> {:cont, {[x | acc], counter - 1}}
    end)
  end

  @doc false
  @spec next(integer, Enumerable.continuation()) :: {nil | [any()], Enumerable.continuation()}
  def next(_demand, continuation) when is_atom(continuation) do
    # nothing produced, returns nil in this case...
    {nil, continuation}
    # TODO: Shall we halt on nil ?? or keep it around ??
    # or maybe have a reset() that reuses the acc ??
    #  cf. gen_stage.streamer module for ideas...
  end

  def next(demand, continuation) do
    case continuation.({:cont, {[], demand}}) do
      {:suspended, {list, 0}, continuation} ->
        {:lists.reverse(list), continuation}

      # TODO : maybe explicitly list possible statuses to avoid unexpected cases ?
      # :halted, :done , anything else ??
      {status, {list, _}} ->
        #        IO.inspect(status)
        # Do we need to keep more things around than only "status" ?
        {:lists.reverse(list), status}
    end
  end
end

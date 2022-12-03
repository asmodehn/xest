defmodule XestClock.Monotone.Reducers do
  defmacro uniq_by_once(callback, fun \\ nil) do
    quote do
      fn entry, acc(head, prev, tail) = original ->
        value = unquote(callback).(entry)

        if Map.has_key?(prev, value) do
          skip(original)
        else
          next_with_acc(unquote(fun), entry, head, Map.put(prev, value, true), tail)
        end
      end
    end
  end
end

defmodule XestClock.Stream.Limiter do
  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System
  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.Process

  @doc """
      A stream operator to prevent going upstream to pick more elements,
      based on a rate (time_unit)
  """
  @spec limiter(Enumerable.t(), System.time_unit()) :: Enumerable.t()

  def limiter(enum, rate) when is_atom(rate) do
    case rate do
      :second -> limiter(enum, 1)
      :millisecond -> limiter(enum, 1_000)
      :microsecond -> limiter(enum, 1_000_000)
      :nanosecond -> limiter(enum, 1_000_000_000)
    end
  end

  def limiter(enum, rate) when is_integer(rate) do
    # Note: unit is defined before computation in stream, and the same for all elements.
    best_unit =
      cond do
        rate <= 1 -> :second
        rate <= 1_000 -> :millisecond
        rate <= 1_000_000 -> :microsecond
        rate <= 1_000_000_000 -> :nanosecond
      end

    Stream.transform(enum, nil, fn
      i, nil ->
        {[i], {i, System.monotonic_time(best_unit)}}

      i, {_, ts} ->
        now = System.monotonic_time(best_unit)

        delta_ms = System.convert_time_unit(now - ts, best_unit, :millisecond)
        period_ms = div(1_000, rate)

        # if the current time is far enough from previous ts
        to_wait = period_ms - delta_ms
        # timeout always in milliseconds !

        if to_wait >= 0 do
          Process.sleep(to_wait)
        end

        # take the new element and timestamp it
        {[i], {i, now}}
    end)
  end
end

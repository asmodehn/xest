defmodule XestClock.Stream.Timed do
  @moduledoc """
    A module to deal with stream that have a time constraint.

    Note all the times here should be **local**, as it doesnt make sense
      to use approximative remote measurements inside a stream.
  """

  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System

  alias XestClock.Stream.Timed.LocalStamp

  @spec timed(Enumerable.t(), System.time_unit()) :: Enumerable.t()
  def timed(enum, precision \\ System.native_time_unit())

  def timed(enum, precision) when is_atom(precision) do
    case precision do
      :second -> timed(enum, 1)
      :millisecond -> timed(enum, 1_000)
      :microsecond -> timed(enum, 1_000_000)
      :nanosecond -> timed(enum, 1_000_000_000)
    end
  end

  def timed(enum, precision) when is_integer(precision) do
    # Note: unit is defined before computation in stream, and the same for all elements.
    best_unit =
      cond do
        precision <= 1 -> :second
        precision <= 1_000 -> :millisecond
        precision <= 1_000_000 -> :microsecond
        precision <= 1_000_000_000 -> :nanosecond
      end

    Stream.transform(enum, nil, fn
      i, nil ->
        now = LocalStamp.now(best_unit)
        {[{i, now}], now}

      i, %LocalStamp{} = lts ->
        now = LocalStamp.now(best_unit) |> LocalStamp.with_previous(lts)
        {[{i, now}], now}
    end)
  end

  def untimed(enum) do
    Enum.map(enum, fn
      {original_elem, %LocalStamp{}} -> original_elem
    end)
  end
end

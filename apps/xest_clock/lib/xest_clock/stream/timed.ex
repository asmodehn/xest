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

    # We process the first timestamp to initialize on the call directly !
    # This seems more intuitive than waiting for two whole requests to get offset in stream ?
    # TODO : first_time_stamp
    # or maybe offset should be only computed internally where needed ??

    Stream.map(enum, fn
      i ->
        now = LocalStamp.now(best_unit)
        {i, now}
    end)
  end

  def untimed(enum) do
    Stream.map(enum, fn
      {original_elem, %LocalStamp{}} -> original_elem
    end)
  end
end

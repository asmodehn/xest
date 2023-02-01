defmodule XestClock.Stream.Limiter do
  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System
  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.Process

  alias XestClock.Time
  alias XestClock.Stream.Timed
  # TODO : this should probably be part of timed ... as a timed stream is required...

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
    Stream.map(enum, fn
      {untimed_elem, %Timed.LocalStamp{monotonic: %Time.Value{offset: offset}} = lts}
      when not is_nil(offset) ->
        # this is expected to return 0 if rate is too high
        period_ms = div(1_000, rate)

        # if the current time is far enough from previous ts
        to_wait = period_ms - offset
        # timeout always in milliseconds !

        # SIDE_EFFECT !
        if to_wait > 0, do: Process.sleep(to_wait)
        {untimed_elem, lts}

      # pass-through otherwise
      {untimed_elem, %Timed.LocalStamp{} = lts} ->
        {untimed_elem, lts}
    end)
  end

  #
  #  def limiter(enum, rate) when is_integer(rate) do
  #    Stream.transform(enum, nil, fn
  #      {i, %Timed.LocalStamp{} = lts}, nil ->
  #        # we save lst as acc to be checked by next element
  #        {[{i, lts}], lts}
  #
  #      {i, %Timed.LocalStamp{} = new_lts}, %Timed.LocalStamp{} = last_lts ->
  #
  #        timestamp = new_lts
  #        |> TimeValue.with_derivatives_from(last_lts)
  #
  #        elapsed = Timed.LocalStamp.diff(new_lts, last_lts)
  #
  #        delta_ms = System.convert_time_unit(elapsed.monotonic, elapsed.unit, :millisecond)
  #        # otherwise, this is expected to return 0
  #        period_ms = div(1_000, rate)
  #
  #        # if the current time is far enough from previous ts
  #        to_wait = period_ms - delta_ms
  #        # timeout always in milliseconds !
  #
  #        # SIDE_EFFECT !
  #        if to_wait > 0, do: Process.sleep(to_wait)
  #
  #        # return the new element and store its timestamp
  #        {[{i, new_lts}], new_lts}
  #    end)
  #  end
end

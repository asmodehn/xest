defmodule XestClock.Clock.Stream do
  @docmodule """
    A Clock as a Stream, directly.
  """

  alias XestClock.Monotone
  alias XestClock.Timestamp
  alias XestClock.Clock.Timeunit

  def stream(:local, unit) do
    nu = Timeunit.normalize(unit)

    stream(
      :local,
      nu,
      Stream.repeatedly(
        # getting local time  monotonically
        fn -> System.monotonic_time(nu) end
      )
    )
  end

  @doc """
    A stream representing the timeflow, ie a clock.
  """
  @spec stream(atom(), System.time_unit(), Enumerable.t()) :: Enumerable.t()
  def stream(origin, unit, tickstream) do
    nu = Timeunit.normalize(unit)

    tickstream
    # guaranteeing strict monotonicity
    |> Monotone.increasing()
    |> Stream.dedup()
    # TODO : offset (non-monotonic !) before timestamp, or after ???
    #   => is Timestamp monotonic (distrib), or local ???
    |> Stream.map(fn v -> Timestamp.new(origin, nu, v) end)
  end

  @spec stream(atom(), System.time_unit(), Enumerable.t(), integer) :: Enumerable.t()
  def stream(origin, unit, tickstream, offset) do
    nu = Timeunit.normalize(unit)

    tickstream
    # guaranteeing strict monotonicity
    |> Monotone.increasing()
    |> Stream.dedup()
    # apply the offset on the integer before outputting (possibly non monotonic) timestamp.
    |> Stream.map(fn v -> v + offset end)
    # TODO : offset (non-monotonic !) before timestamp, or after ???
    #   => is Timestamp monotonic (distrib), or local ???
    |> Stream.map(fn v -> Timestamp.new(origin, nu, v) end)
  end
end

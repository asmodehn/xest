defmodule XestClock.Clock.Stream do
  @docmodule """
    A Clock as a Stream, directly.
  """

  # TODO : replace XestClock.Clock with this...

  alias XestClock.Monotone
  alias XestClock.Timestamp
  alias XestClock.Clock.Timeunit

  @enforce_keys [:unit, :stream, :origin]
  defstruct unit: nil,
            # TODO: if Enumerable, some Enum function might consume elements implicitely (like Enum.at())
            stream: nil,
            # TODO: get rid of this ? makes sens only when comparing many of them...
            origin: nil

  @typedoc "XestClock.Clock struct"
  @type t() :: %__MODULE__{
          unit: System.time_unit(),
          # TODO : convert enum to clock and back...
          stream: Enumerable.t(),
          origin: atom
        }

  def new(:local, unit) do
    nu = Timeunit.normalize(unit)

    new(
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
  # TODO : clearer name : from_tickstream
  @spec new(atom(), System.time_unit(), Enumerable.t()) :: Enumerable.t()
  def new(origin, unit, tickstream) do
    nu = Timeunit.normalize(unit)

    %__MODULE__{
      origin: origin,
      unit: nu,
      stream:
        tickstream
        # guaranteeing strict monotonicity
        |> Monotone.increasing()
        |> Stream.dedup()
      # TODO : offset (non-monotonic !) before timestamp, or after ???
      #   => is Timestamp monotonic (distrib), or local ???
      #    |> Stream.map(fn v -> Timestamp.new(origin, nu, v) end)
    }
  end

  @doc """
    Implements the enumerable protocol for a clock, so that it can be used as a `Stream`.
  """
  defimpl Enumerable, for: __MODULE__ do
    # early errors (duplicating stream code here to get the correct module in case of error)
    def count(_clock), do: {:error, __MODULE__}

    def member?(_clock, _value), do: {:error, __MODULE__}

    def slice(_clock), do: {:error, __MODULE__}

    # managing halt and suspended here (in case we might want to do something to the clock struct ?)
    def reduce(_clock, {:halt, acc}, _fun), do: {:halted, acc}
    def reduce(clock, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(clock, &1, fun)}

    # delegating continuing reduce to the generic Enumerable implementation of reduce
    def reduce(clock, {:cont, acc}, fun) do
      # we do not need to do anything with the result (used internally by the stream)
      Enumerable.reduce(clock.stream, {:cont, acc}, fun)
    end
  end

  #  @spec stream(atom(), System.time_unit(), Enumerable.t(), integer) :: Enumerable.t()
  #  def stream(origin, unit, tickstream, offset) do
  #    nu = Timeunit.normalize(unit)
  #
  #    tickstream
  #    # guaranteeing strict monotonicity
  #    |> Monotone.increasing()
  #    |> Stream.dedup()
  #    # apply the offset on the integer before outputting (possibly non monotonic) timestamp.
  #    |> Stream.map(fn v -> v + offset end)
  #    # TODO : offset (non-monotonic !) before timestamp, or after ???
  #    #   => is Timestamp monotonic (distrib), or local ???
  #    |> Stream.map(fn v -> Timestamp.new(origin, nu, v) end)
  #  end

  @spec as_timestamp(t()) :: Enumerable.t()
  def as_timestamp(%__MODULE__{} = clockstream) do
    # take the clock stream and map to get a timestamp
    clockstream.stream
    |> Stream.map(fn cs ->
      %XestClock.Timestamp{
        origin: clockstream.origin,
        unit: clockstream.unit,
        # No offset allowed for monotone clock stream.
        ts: cs
      }
    end)
  end

  @spec convert(t(), System.time_unit()) :: t()
  def convert(%__MODULE__{} = clockstream, unit) do
    %{
      clockstream
      | stream:
          clockstream.stream
          |> Stream.map(fn ts -> Timeunit.convert(ts, clockstream.unit, unit) end),
        unit: unit
    }
  end

  @spec offset(t(), t()) :: Timestamp.t()
  def offset(%__MODULE__{} = clockstream, %__MODULE__{} = otherclock) do
    # Here we need timestamp for the unit, to be able to compare integers...

    Stream.zip(
      otherclock |> as_timestamp(),
      clockstream |> as_timestamp()
    )
    |> Stream.map(fn {a, b} ->
      Timestamp.diff(a, b)
    end)
    |> Enum.at(0)

    # Note : we return only one element, as returning a stream might not make much sense ??
    # Later skew and more can be evaluated more cleverly, but just a set of values will be returned here,
    # not a stream.
  end

  # TODO : estimate linear deviation...
end

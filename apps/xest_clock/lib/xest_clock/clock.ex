defmodule XestClock.Clock do
  @docmodule """
    A Clock as a Stream.

  This module contains only the data structure and necessary functions.

  For usage, there are two cases :
   - local
   - remote
  and various functions are provided
  """

  alias XestClock.Monotone
  alias XestClock.Timestamp
  alias XestClock.Clock.Timeunit

  @enforce_keys [:unit, :stream, :origin]
  defstruct unit: nil,
            # TODO: if Enumerable, some Enum function might consume elements implicitely (like Enum.at())
            stream: nil,
            # TODO: get rid of this ? makes sens only when comparing many of them...
            origin: nil,
            offset: %Timestamp{
              origin: :testremote,
              unit: :second,
              ts: 0
            }

  @typedoc "XestClock.Clock struct"
  @type t() :: %__MODULE__{
          unit: System.time_unit(),
          # TODO : convert enum to clock and back...
          stream: Enumerable.t(),
          origin: atom,
          offset: Timestamp.t()
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
  @spec new(atom(), System.time_unit(), Enumerable.t(), integer) :: Enumerable.t()
  def new(origin, unit, tickstream, offset \\ 0) do
    nu = Timeunit.normalize(unit)

    %__MODULE__{
      origin: origin,
      unit: nu,
      stream:
        tickstream
        # guaranteeing strict monotonicity
        |> Monotone.increasing()
        |> Stream.dedup(),
      offset: Timestamp.new(origin, nu, offset)
    }
  end

  @doc """
      add_offset adds an offset to the clock
  """
  @spec add_offset(t(), Timestamp.t()) :: t()
  def add_offset(%__MODULE__{} = clock, %Timestamp{} = offset) do
    %{
      clock
      | # Note : order matter in plus() regarding origin in Timestamp...
        offset: Timestamp.plus(offset, clock.offset)
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

  @doc """
    follow determines the offset with the followed clock and adds it to the current clock
  """
  @spec follow(t(), t()) :: t()
  def follow(%__MODULE__{} = clock, %__MODULE__{} = followed) do
    clock
    |> add_offset(offset(clock, followed))
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
      Timestamp.plus(
        # build a timestamp from the clock tick
        %XestClock.Timestamp{
          origin: clockstream.origin,
          unit: clockstream.unit,
          # No offset allowed for monotone clock stream.
          ts: cs
        },
        # add the offset
        clockstream.offset
      )
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

  @spec to_datetime(t(), (System.time_unit() -> integer)) :: Enumerable.t()
  def to_datetime(%__MODULE__{} = clock, monotone_time_offset \\ &System.time_offset/1) do
    clock
    |> as_timestamp()
    |> Stream.map(fn ts ->
      tstamp =
        Timestamp.plus(
          # take the clock tick as a timestamp
          ts,
          Timestamp.new(
            # add the local monotone_time VM offset
            :time_offset,
            clock.unit,
            monotone_time_offset.(clock.unit)
          )
        )

      DateTime.from_unix!(tstamp.ts, tstamp.unit)
    end)
  end
end

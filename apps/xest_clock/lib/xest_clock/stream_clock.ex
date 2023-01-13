defmodule XestClock.StreamClock do
  @moduledoc """
    A Clock as a Stream.

  This module contains only the data structure and necessary functions.

  """

  alias XestClock.Monotone
  alias XestClock.Timestamp
  alias XestClock.Timeunit

  @enforce_keys [:unit, :stream, :origin]
  defstruct unit: nil,
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

  The calling code can pass an enumerable, for deterministic testing for example:

  iex> enum_clock = XestClock.StreamClock.new(:enum_clock, :millisecond, [1,2,3,4,5])
  iex(1)> Enum.to_list(enum_clock)
  [1, 2, 3, 4, 5]

  A stream is also an enumerable, and can be formed from a function called repeatedly.
    Note a constant clock is monotonous, and therefore valid.

  iex> call_clock = XestClock.StreamClock.new(:call_clock, :millisecond, Stream.repeatedly(fn -> 42 end))
  iex(1)> call_clock |> Enum.take(3) |> Enum.to_list()

    The specific local clock is accessible via new(:local, :millisecond)

  iex> local_clock = XestClock.StreamClock.new(:local, :millisecond)
  iex(1)> local_clock |> Enum.take(1) |> Enum.to_list()

  Note : to be able to get one tick at a time from the clock (from the stream),
  you ll probably need an agent or some gen_server to keep state around...

  """
  @spec new(atom(), System.time_unit(), Enumerable.t(), integer) :: Enumerable.t()
  def new(origin, unit, tickstream, offset \\ 0) do
    nu = Timeunit.normalize(unit)

    %__MODULE__{
      origin: origin,
      unit: nu,
      stream:
        tickstream
        # guaranteeing (weak) monotonicity
        # Less surprising for the user than a strict monotonicity dropping elements.
        |> Monotone.increasing(),
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
    # TODO :careful with loss of precision !!
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

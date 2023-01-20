defmodule XestClock.StreamClock do
  @moduledoc """
    A Clock as a Stream of timestamps

  This module contains only the data structure and necessary functions.

  """

  # TODO : this should probably be called just "Stream"

  # intentionally hiding Elixir.System
  alias XestClock.System

  alias XestClock.Monotone
  alias XestClock.Timestamp

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
    nu = System.Extra.normalize_time_unit(unit)

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
  [
  %XestClock.Timestamp{origin: :enum_clock, ts: 1, unit: :millisecond},
  %XestClock.Timestamp{origin: :enum_clock, ts: 2, unit: :millisecond},
  %XestClock.Timestamp{origin: :enum_clock, ts: 3, unit: :millisecond},
  %XestClock.Timestamp{origin: :enum_clock, ts: 4, unit: :millisecond},
  %XestClock.Timestamp{origin: :enum_clock, ts: 5, unit: :millisecond}
  ]

  A stream is also an enumerable, and can be formed from a function called repeatedly.
    Note a constant clock is monotonous, and therefore valid.

  iex> call_clock = XestClock.StreamClock.new(:call_clock, :millisecond, Stream.repeatedly(fn -> 42 end))
  iex(1)> call_clock |> Enum.take(3) |> Enum.to_list()

  Note : to be able to get one tick at a time from the clock (from the stream),
  you ll probably need an agent or some gen_server to keep state around...

  Note: The stream returns nil only before it has been initialized. If after a while, no new tick is in the stream, it will return the last known tick value.
    This keeps the weak monotone semantics, simplify the usage, while keeping the nil value in case internal errors were detected, and streamclock needs to be reinitialized.
  """
  @spec new(atom(), System.time_unit(), Enumerable.t(), integer) :: Enumerable.t()
  def new(origin, unit, tickstream, offset \\ 0) do
    nu = System.Extra.normalize_time_unit(unit)

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

    Stream.zip(otherclock, clockstream)
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

    # reducing a streamclock produces timestamps
    def reduce(clock, {:cont, acc}, fun) do
      clock.stream
      |> Stream.map(fn cs ->
        Timestamp.plus(
          # build a timestamp from the clock tick
          %XestClock.Timestamp{
            origin: clock.origin,
            unit: clock.unit,
            ts: cs
          },
          # add the offset
          clock.offset
        )
      end)
      # delegating continuing reduce to the generic Enumerable implementation of reduce
      |> Enumerable.reduce({:cont, acc}, fun)
    end
  end

  @spec convert(t(), System.time_unit()) :: t()
  def convert(%__MODULE__{} = clockstream, unit) do
    # TODO :careful with loss of precision !!
    %{
      clockstream
      | stream:
          clockstream.stream
          |> Stream.map(fn ts -> System.convert_time_unit(ts, clockstream.unit, unit) end),
        unit: unit
    }
  end

  # TODO : move that to a Datetime module specific for those APIs...
  #  find how to relate to from_unix DateTime API... maybe using a clock process ??
  @doc """
    from_unix! expects a clock and returns the current datetime of that clock, with the local timezone information.
    The system timezone is assumed, in order to stay close to Elixir interface.
  """
  @spec to_datetime(XestClock.StreamClock.t(), (System.time_unit() -> integer)) :: Enumerable.t()
  def to_datetime(%__MODULE__{} = clock, monotone_time_offset \\ &System.time_offset/1) do
    clock
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

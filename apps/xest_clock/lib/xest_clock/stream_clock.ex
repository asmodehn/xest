defmodule XestClock.StreamClock do
  @moduledoc """
    A Clock as a Stream of timestamps

  This module contains only the data structure and necessary functions.

  """

  # TODO : this should probably be called just "Stream"

  # intentionally hiding Elixir.System
  alias XestClock.System

  alias XestClock.Stream.Monotone
  alias XestClock.Time

  @enforce_keys [:stream, :origin]
  defstruct stream: nil,
            # TODO: get rid of this ? makes sens only when comparing many of them...
            origin: nil,
            # TODO : change to a time value... or maybe get rid of it entirely ?
            offset: Time.Stamp.new(:testremote, :second, 0)

  @typedoc "XestClock.Clock struct"
  @type t() :: %__MODULE__{
          stream: Enumerable.t(),
          origin: atom,
          offset: Time.Stamp.t()
        }

  # TODO : get rid of it. we abuse design here. it was just aimed to be an example...
  def new(System, unit) do
    nu = System.Extra.normalize_time_unit(unit)

    # Note we switch to use XestClock.System to be able to mock in tests.
    new(
      XestClock.System,
      nu,
      Stream.repeatedly(
        # getting local time  monotonically
        fn -> System.monotonic_time(nu) end
      )
    )
  end

  @doc """
    A stream representing the timeflow, ie a clock.

  The calling code can pass an enumerable, which is useful for deterministic testing.

  The value should be monotonic, and is taken as a measurement of time.
  Derivatives are calculated on it (offset and skew) to help with various runtime requirements regarding clocks.

  For example, after using stub code for system to side-step the mocks for tests:

  iex> Hammox.stub_with(XestClock.System.OriginalMock, XestClock.System.OriginalStub)
  iex(1)> Hammox.stub_with(XestClock.System.ExtraMock, XestClock.System.ExtraStub)
  iex(2)> enum_clock = XestClock.StreamClock.new(:enum_clock, :millisecond, [1,2,3])
  iex(3)> Enum.to_list(enum_clock)
  [
  %XestClock.Time.Stamp{
      origin: :enum_clock,
      ts: %XestClock.Time.Value{
          value: 1,
          offset: nil,
          unit: :millisecond
  }},
  %XestClock.Time.Stamp{
      origin: :enum_clock,
      ts: %XestClock.Time.Value{
          value: 2,
          offset: 1,
          unit: :millisecond
      }},
  %XestClock.Time.Stamp{
      origin: :enum_clock,
      ts: %XestClock.Time.Value{
          value: 3,
          offset: 1,
          unit: :millisecond
  }}
  ]

  A stream is also an enumerable, and can be formed from a function called repeatedly.
    Note a constant clock is monotonous, and therefore valid.

  iex> Hammox.stub_with(XestClock.System.OriginalMock, XestClock.System.OriginalStub)
  iex(1)> Hammox.stub_with(XestClock.System.ExtraMock, XestClock.System.ExtraStub)
  iex(2)> call_clock = XestClock.StreamClock.new(:call_clock, :millisecond, Stream.repeatedly(fn -> 42 end))
  iex(3)> call_clock |> Enum.take(3) |> Enum.to_list()

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
      stream:
        tickstream
        # guaranteeing (weak) monotonicity
        # Less surprising for the user than a strict monotonicity dropping elements.
        |> Monotone.increasing()
        # from an int to a timevalue
        |> as_timevalue(nu),
      # add current local time for relative computations
      # TODO : extract this timed stream into a specific type to simplify stream computations
      # There should be a naive clock, and a clock with origin (to add proxy/timestamp behavior...)
      #        |> Timed.timed()
      #        # TODO : limiter : requests should not be faster than precision unit
      #        # TODO : analyse current time vs received time to determine if we *should* request another, or just emulate (proxy)...
      #        |> Limiter.limiter(nu)
      #        # TODO : add proxy, in stream !
      #        # remove current local time
      #        |> Timed.untimed(),

      # REMINDER: consuming the clock.stream directly should be "naive" (no idea of origin-from users point of view).
      # This is the point of the clock. so the internal stream is only naive time values...
      offset: Time.Stamp.new(origin, nu, offset)
    }
  end

  defp as_timevalue(enum, unit) do
    Stream.transform(enum, nil, fn
      i, nil ->
        now = Time.Value.new(unit, i)
        # keep the current value in accumulator to compute derivatives later
        {[now], now}

      i, %Time.Value{} = ltv ->
        #        IO.inspect(ltv)
        now = Time.Value.new(unit, i) |> Time.Value.with_previous(ltv)
        {[now], now}
    end)
  end

  #  @doc """
  #      add_offset adds an offset to the clock
  #  """
  #  @spec add_offset(t(), Timestamp.t()) :: t()
  #  def add_offset(%__MODULE__{} = clock, %Timestamp{} = offset) do
  #    %{
  #      clock
  #      | # Note : order matter in plus() regarding origin in Timestamp...
  #        offset: Timestamp.plus(offset, clock.offset)
  #    }
  #  end

  #  @spec offset(t(), t()) :: Timestamp.t()
  #  def offset(%__MODULE__{} = clockstream, %__MODULE__{} = otherclock) do
  #    # Here we need timestamp for the unit, to be able to compare integers...
  #
  #    Stream.zip(otherclock, clockstream)
  #    |> Stream.map(fn {a, b} ->
  #      Timestamp.diff(a, b)
  #    end)
  #    |> Enum.at(0)
  #
  #    # Note : we return only one element, as returning a stream might not make much sense ??
  #    # Later skew and more can be evaluated more cleverly, but just a set of values will be returned here,
  #    # not a stream.
  #  end

  #  @doc """
  #    follow determines the offset with the followed clock and adds it to the current clock
  #  """
  #  @spec follow(t(), t()) :: t()
  #  def follow(%__MODULE__{} = clock, %__MODULE__{} = followed) do
  #    clock
  #    |> add_offset(offset(clock, followed))
  #  end

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
      # as timestamp, only when we consume from the clock itself.
      |> as_timestamp(clock.origin)
      # delegating continuing reduce to the generic Enumerable implementation of reduce
      |> Enumerable.reduce({:cont, acc}, fun)
    end

    defp as_timestamp(enum, origin) do
      Stream.map(enum, fn elem -> %Time.Stamp{origin: origin, ts: elem} end)
    end

    # TODO : timed reducer based on unit ??
    # We dont want the enumeration to be faster than the unit...
  end

  @spec convert(t(), System.time_unit()) :: t()
  def convert(%__MODULE__{} = clockstream, unit) do
    # TODO :careful with loss of precision !!
    %{
      clockstream
      | stream:
          clockstream.stream
          |> Stream.map(fn ts -> System.convert_time_unit(ts.value, ts.unit, unit) end)
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
    |> Stream.map(fn %Time.Value{value: mt, unit: unit} ->
      DateTime.from_unix!(mt + monotone_time_offset.(unit), unit)
    end)
  end
end

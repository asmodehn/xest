defmodule XestClock.Time.Value do
  @moduledoc """
  This module holds time values.
  It is use for implicit conversion between various units when doing time arithmetic
  """

  # TODO : time value as a protocol ? (we have local timestamps, remote timestamp, offset, at least!)

  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System

  @enforce_keys [:unit, :value]
  defstruct unit: nil,
            value: nil,
            error: 0

  @typedoc "TimeValue struct"
  @type t() :: %__MODULE__{
          unit: System.time_unit(),
          value: integer(),
          # usually assumed to be much smaller than value.
          error: integer()
        }

  # TODO : keep making the same mistake when writing -> reverse params ?
  def new(unit, value, error \\ 0) when is_integer(value) and is_integer(error) do
    %__MODULE__{
      unit: System.Extra.normalize_time_unit(unit),
      value: value,
      # error is always positive (expressed as deviation from value)
      error: abs(error)
    }
  end

  @spec convert(t(), System.time_unit()) :: t()
  def convert(%__MODULE__{} = tv, unit) when tv.unit == unit, do: tv

  def convert(%__MODULE__{} = tv, unit) do
    new(
      unit,
      System.convert_time_unit(
        tv.value,
        tv.unit,
        unit
      ),
      System.convert_time_unit(
        tv.error,
        tv.unit,
        unit
      )
    )
  end

  def diff(%__MODULE__{} = tv1, %__MODULE__{} = tv2) do
    if System.convert_time_unit(1, tv1.unit, tv2.unit) < 1 do
      # invert conversion to avoid losing precision
      new(
        tv1.unit,
        tv1.value - convert(tv2, tv1.unit).value,
        # CAREFUL: error is compounded (can go two ways, it represents an interval)!
        tv1.error + convert(tv2, tv1.unit).error
      )
    else
      new(
        tv2.unit,
        convert(tv1, tv2.unit).value - tv2.value,
        convert(tv1, tv2.unit).error + tv2.error
      )
    end
  end

  def sum(%__MODULE__{} = tv1, %__MODULE__{} = tv2) do
    if System.convert_time_unit(1, tv1.unit, tv2.unit) < 1 do
      # invert conversion to avoid losing precision
      new(
        tv1.unit,
        tv1.value + convert(tv2, tv1.unit).value,
        tv1.error + convert(tv2, tv1.unit).error
      )
    else
      new(
        tv2.unit,
        convert(tv1, tv2.unit).value + tv2.value,
        convert(tv1, tv2.unit).error + tv2.error
      )
    end
  end

  # TODO : linear map on time values ??
  def scale(%__MODULE__{} = tv, factor) when is_float(factor) do
    new(
      tv.unit,
      round(tv.value * factor),
      round(tv.error * factor)
    )
  end

  def scale(%__MODULE__{} = tv, factor) when is_integer(factor) do
    new(
      tv.unit,
      tv.value * factor,
      tv.error * factor
    )
  end

  @doc """
    Take a stream of integer, and transform it to a stream of timevalues.
    The stream may contain local timestamps.
  """
  def stream(enum, unit) do
    # TODO : map instead ?
    Stream.transform(
      enum |> XestClock.Stream.monotone_increasing(),
      nil,
      fn
        {i, %XestClock.Stream.Timed.LocalStamp{} = ts}, nil ->
          now = new(unit, i)
          # keep the current value in accumulator to compute derivatives later
          {[{now, ts}], now}

        i, nil ->
          now = new(unit, i)
          # keep the current value in accumulator to compute derivatives later
          {[now], now}

        {i, %XestClock.Stream.Timed.LocalStamp{} = ts}, %__MODULE__{} = _ltv ->
          #        IO.inspect(ltv)
          now = new(unit, i)
          {[{now, ts}], now}

        i, %__MODULE__{} = _ltv ->
          #        IO.inspect(ltv)
          now = new(unit, i)
          {[now], now}
      end
    )
  end
end

defimpl String.Chars, for: XestClock.Time.Value do
  def to_string(%XestClock.Time.Value{
        value: ts,
        unit: unit
      }) do
    # TODO: maybe have a more systematic / global way to manage time unit ??
    # to something that is immediately parseable ? some sigil ??
    # some existing physical unit library ?

    unit =
      case unit do
        :second -> "s"
        :millisecond -> "ms"
        :microsecond -> "μs"
        :nanosecond -> "ns"
        pps -> " @ #{pps} Hz"
      end

    "#{ts} #{unit}"
  end
end

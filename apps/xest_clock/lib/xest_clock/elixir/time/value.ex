defmodule XestClock.Time.Value do
  @moduledoc """
  This module holds time values.
  It is use for implicit conversion between various units when doing time arithmetic
  """

  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System

  @enforce_keys [:unit, :value]
  defstruct unit: nil,
            value: nil

  # TODO: offset is useful but could probably be transferred inside the stream operators, where it is used
  # TODO: we should add a precision / error interval
  # => measurements, although late, will have interval in connection time scale,
  # => estimation will have error interval in estimation (max current offset) time scale

  @typedoc "TimeValue struct"
  @type t() :: %__MODULE__{
          unit: System.time_unit(),
          value: integer()
        }

  # TODO : keep making the same mistake -> reverse params ?
  def new(unit, value) when is_integer(value) do
    %__MODULE__{
      unit: System.Extra.normalize_time_unit(unit),
      value: value
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
      )
    )
  end

  def diff(%__MODULE__{} = tv1, %__MODULE__{} = tv2) do
    if System.convert_time_unit(1, tv1.unit, tv2.unit) < 1 do
      # invert conversion to avoid losing precision
      %__MODULE__{
        unit: tv1.unit,
        value: tv1.value - convert(tv2, tv1.unit).value
      }
    else
      %__MODULE__{
        unit: tv2.unit,
        value: convert(tv1, tv2.unit).value - tv2.value
      }
    end
  end

  def sum(%__MODULE__{} = tv1, %__MODULE__{} = tv2) do
    if System.convert_time_unit(1, tv1.unit, tv2.unit) < 1 do
      # invert conversion to avoid losing precision
      %__MODULE__{
        unit: tv1.unit,
        value: tv1.value + convert(tv2, tv1.unit).value
      }
    else
      %__MODULE__{
        unit: tv2.unit,
        value: convert(tv1, tv2.unit).value + tv2.value
      }
    end
  end

  # TODO : linear map on time values ??
  def scale(%__MODULE__{} = tv, factor) do
    %__MODULE__{
      unit: tv.unit,
      value: round(tv.value * factor)
    }
  end

  @spec div(t(), t()) :: float
  def div(%__MODULE__{} = tv_num, %__MODULE__{} = _tv_den)
      # no offset
      when tv_num.value == 0,
      do: 0.0

  def div(%__MODULE__{} = tv_num, %__MODULE__{} = tv_den)
      when tv_den.value != 0 do
    if System.convert_time_unit(1, tv_num.unit, tv_den.unit) < 1 do
      # invert conversion to avoid losing precision
      tv_num.value / convert(tv_den, tv_num.unit).value
    else
      convert(tv_num, tv_den.unit).value / tv_den.value
    end
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

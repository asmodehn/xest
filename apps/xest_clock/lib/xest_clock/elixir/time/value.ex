defmodule XestClock.Time.Value do
  @moduledoc """
  This module holds time values.
  It is use for implicit conversion between various units when doing time arithmetic
  """

  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System

  @enforce_keys [:unit, :value]
  defstruct unit: nil,
            value: nil,
            # TODO : handle derivative separately
            # first order derivative, the difference of two monotonic values.
            offset: nil

  # TODO :skew seems useless, lets get rid of it..
  # TODO: offset is useful but could probably be transferred inside the stream operators, where it is used
  # TODO: we should add a precision / error interval
  # => measurements, although late, will have interval in connection time scale,
  # => estimation will have error interval in estimation (max current offset) time scale

  @typedoc "TimeValue struct"
  @type t() :: %__MODULE__{
          unit: System.time_unit(),
          value: integer(),
          # TODO : separate this out ? or call it differently ? it "offset" from last tick...
          # ideas : "bump", "progress", "increase"
          # TODO : maybe only have it inside stream transformers ?
          offset: integer()
        }

  @derive {Inspect, optional: [:offset]}

  def new(unit, value) when is_integer(value) do
    %__MODULE__{
      unit: System.Extra.normalize_time_unit(unit),
      value: value
    }
  end

  def with_previous(%__MODULE__{} = current, %__MODULE__{} = previous)
      when current.unit == previous.unit do
    %{
      current
      | offset: current.value - previous.value
    }
  end

  @spec convert(t(), System.time_unit()) :: t()
  def convert(%__MODULE__{} = tv, unit) when tv.unit == unit, do: tv

  def convert(%__MODULE__{} = tv, unit) do
    %{
      new(
        unit,
        System.convert_time_unit(
          tv.value,
          tv.unit,
          unit
        )
      )
      | offset:
          System.convert_time_unit(
            tv.offset,
            tv.unit,
            unit
          )
    }
  end

  def diff(%__MODULE__{} = tv1, %__MODULE__{} = tv2) do
    if System.convert_time_unit(1, tv1.unit, tv2.unit) < 1 do
      # invert conversion to avoid losing precision
      %__MODULE__{
        unit: tv1.unit,
        value: tv1.value - System.convert_time_unit(tv2.value, tv2.unit, tv1.unit)
        # Note: previous existing offset in tv1 and tv2 loses any meaning.
      }
    else
      %__MODULE__{
        unit: tv2.unit,
        value: System.convert_time_unit(tv1.value, tv1.unit, tv2.unit) - tv2.value
        # Note: previous existing offset in tv1 and tv2 loses any meaning.
      }
    end
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
        pps -> " @ #{pps} Hz}"
      end

    "#{ts} #{unit}"
  end
end

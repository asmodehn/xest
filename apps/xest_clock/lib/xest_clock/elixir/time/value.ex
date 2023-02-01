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
            offset: nil,
            # the first order derivative of offsets.
            skew: nil

  # TODO :skew seems useless, lets get rid of it..
  # TODO: offset is useful but could probably be transferred inside the stream operators, where it is used
  # TODO: we should add a precision / error interval
  # => measurements, although late, will have interval in connection time scale,
  # => estimation will have error interval in estimation (max current offset) time scale

  @typedoc "TimeValue struct"
  @type t() :: %__MODULE__{
          unit: System.time_unit(),
          value: integer(),
          offset: integer(),
          skew: integer()
        }

  @derive {Inspect, optional: [:offset, :skew]}

  def new(unit, value) when is_integer(value) do
    %__MODULE__{
      unit: System.Extra.normalize_time_unit(unit),
      value: value
    }
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

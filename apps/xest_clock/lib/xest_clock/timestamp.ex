defmodule XestClock.Timestamp do
  @moduledoc """
  The `XestClock.Clock.Timestamp` module deals with timestamp struct.
  This struct can store one timestamp.

  Note: time measurement doesn't make any sense without a place of that time measurement.
  Therefore there is no implicit origin conversion possible here,
  and managing the place of measurement is left to the client code.
  """

  # intentionally hiding Elixir.System
  alias XestClock.System

  alias XestClock.TimeValue

  @enforce_keys [:origin, :ts]
  defstruct ts: nil,
            origin: nil

  @typedoc "XestClock.Timestamp struct"
  @type t() :: %__MODULE__{
          ts: TimeValue.t(),
          origin: atom()
        }

  @spec new(atom(), System.time_unit(), integer()) :: t()
  def new(origin, unit, ts) do
    nu = System.Extra.normalize_time_unit(unit)

    %__MODULE__{
      # TODO : should be an already known atom...
      origin: origin,
      # TODO : after getting rid of origin, this becomes just a time value...
      ts: TimeValue.new(nu, ts)
    }
  end

  def with_previous(%__MODULE__{} = recent, %__MODULE__{} = past) do
    %{recent | ts: recent.ts |> TimeValue.with_derivatives_from(past.ts)}
  end

  #
  #  # Note :we are currently abusing timestamp to denote timevalues...
  #  def diff(%__MODULE__{} = tsa, %__MODULE__{} = tsb) do
  #    cond do
  #      # if equality, just diff
  #      tsa.unit == tsb.unit ->
  #        new(tsa.origin, tsa.unit, tsa.ts - tsb.ts)
  #
  #      # if conversion needed to tsb unit
  #      System.Extra.time_unit_sup(tsb.unit, tsa.unit) ->
  #        new(tsa.origin, tsb.unit, System.convert_time_unit(tsa.ts, tsa.unit, tsb.unit) - tsb.ts)
  #
  #      # otherwise (tsa unit)
  #      true ->
  #        new(tsa.origin, tsa.unit, tsa.ts - System.convert_time_unit(tsb.ts, tsb.unit, tsa.unit))
  #    end
  #  end
  #
  #  def plus(%__MODULE__{} = tsa, %__MODULE__{} = tsb) do
  #    cond do
  #      # if equality just add
  #      tsa.unit == tsb.unit ->
  #        new(tsa.origin, tsa.unit, tsa.ts + tsb.ts)
  #
  #      # if conversion needed to tsb unit
  #      System.Extra.time_unit_sup(tsb.unit, tsa.unit) ->
  #        new(tsa.origin, tsb.unit, System.convert_time_unit(tsa.ts, tsa.unit, tsb.unit) + tsb.ts)
  #
  #      # otherwise (tsa unit)
  #      true ->
  #        new(tsa.origin, tsa.unit, tsa.ts + System.convert_time_unit(tsb.ts, tsb.unit, tsa.unit))
  #    end
  #  end
end

defimpl String.Chars, for: XestClock.Timestamp do
  def to_string(%XestClock.Timestamp{
        origin: origin,
        ts: %XestClock.TimeValue{
          monotonic: ts,
          unit: unit
        }
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

    "{#{origin}: #{ts} #{unit}}"
  end
end

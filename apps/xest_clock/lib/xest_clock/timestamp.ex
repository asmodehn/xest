defmodule XestClock.Timestamp do
  @docmodule """
  The `XestClock.Clock.Timestamp` module deals with timestamp struct.
  This struct can store one timestamp.

  Note: time measurement doesn't make any sense without a place of that time measurement.
  Therefore there is no implicit origin conversion possible here,
  and managing the place of measurement is left to the client code.
  """

  alias XestClock.Clock.Timeunit

  @enforce_keys [:origin, :unit, :ts]
  defstruct ts: nil,
            unit: nil,
            origin: nil

  @typedoc "XestClock.Timestamp struct"
  @type t() :: %__MODULE__{
          ts: integer(),
          unit: System.time_unit(),
          origin: atom()
        }

  @spec new(atom(), System.time_unit(), integer()) :: t()
  def new(origin, unit, ts) do
    Timeunit.normalize(unit)

    %__MODULE__{
      # TODO : should be an already known atom...
      origin: origin,
      # TODO : normalize unit (clock ? not private ?)
      unit: unit,
      # TODO : after getting rid of origin, this becomes just a time value...
      ts: ts
    }
  end

  # Note :we are currently abusing timestamp to denote timevalues...
  def diff(%__MODULE__{} = tsa, %__MODULE__{} = tsb) do
    cond do
      # if equality, just diff
      tsa.unit == tsb.unit ->
        new(tsa.origin, tsa.unit, tsa.ts - tsb.ts)

      # if conversion needed to tsb unit
      Timeunit.sup(tsb.unit, tsa.unit) ->
        new(tsa.origin, tsb.unit, Timeunit.convert(tsa.ts, tsa.unit, tsb.unit) - tsb.ts)

      # otherwise (tsa unit)
      true ->
        new(tsa.origin, tsa.unit, tsa.ts - Timeunit.convert(tsb.ts, tsb.unit, tsa.unit))
    end
  end

  def plus(%__MODULE__{} = tsa, %__MODULE__{} = tsb) do
    cond do
      # if equality just add
      tsa.unit == tsb.unit ->
        new(tsa.origin, tsa.unit, tsa.ts + tsb.ts)

      # if conversion needed to tsb unit
      Timeunit.sup(tsb.unit, tsa.unit) ->
        new(tsa.origin, tsb.unit, Timeunit.convert(tsa.ts, tsa.unit, tsb.unit) + tsb.ts)

      # otherwise (tsa unit)
      true ->
        new(tsa.origin, tsa.unit, tsa.ts + Timeunit.convert(tsb.ts, tsb.unit, tsa.unit))
    end
  end
end

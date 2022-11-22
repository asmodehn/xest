defmodule XestClock.Clock.Timeinterval do
  @docmodule """
  The `XestClock.Clock.Timeinterval` module deals with timeinterval struct.
  This struct can store one timeinterval with measurements from the same origin, with the same unit.

  Unit and origin mismatch immediately triggers an exception.
  Note: unit conversion could be done, but would require Arbitrary-Precision Arithmetic
   -> see https://github.com/Vonmo/eapa

  Note: time measurement doesn't make any sense without a place of that time measurement.
  Therefore there is no implicit origin conversion possible here,
  and managing the place of measurement is left to the client code.
  """

  alias XestClock.Clock.Timestamp

  # Note : The interval represented is a time interval -> continuous
  # EVEN IF the encoding interval is discrete (integer)

  @enforce_keys [:origin, :unit, :interval]
  defstruct interval: nil,
            unit: nil,
            origin: nil

  @typedoc "Timeinterval struct"
  @type t() :: %__MODULE__{
          interval: Interval.t(),
          unit: System.time_unit(),
          origin: atom()
        }

  @doc """
  Builds a time interval from two timestamps.
    right and left are determined by comparing the two timestamps
  """
  def build(%Timestamp{} = ts1, %Timestamp{} = ts2) do
    cond do
      ts1.origin != ts2.origin ->
        raise(ArgumentError, message: "time bounds origin mismatch")

      ts1.unit != ts2.unit ->
        raise(ArgumentError, message: "time bounds unit mismatch ")

      ts1.ts == ts2.ts ->
        raise(ArgumentError, message: "time bounds identical. interval would be empty...")

      ts1.ts < ts2.ts ->
        %__MODULE__{
          origin: ts1.origin,
          unit: ts1.unit,
          interval:
            Interval.new(module: Interval.Integer, left: ts1.ts, right: ts2.ts, bounds: "[)")
        }

      ts1.ts > ts2.ts ->
        %__MODULE__{
          origin: ts1.origin,
          unit: ts1.unit,
          interval:
            Interval.new(module: Interval.Integer, left: ts2.ts, right: ts1.ts, bounds: "[)")
        }
    end
  end

  # TODO : validate time unit ??
end

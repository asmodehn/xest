defmodule XestClock.Timeinterval do
  @moduledoc """
  The `XestClock.Clock.Timeinterval` module deals with timeinterval struct.
  This struct can store one timeinterval with measurements from the same origin, with the same unit.

  Unit and origin mismatch immediately triggers an exception.
  Note: unit conversion could be done, but would require Arbitrary-Precision Arithmetic
   -> see https://github.com/Vonmo/eapa

  Note: time measurement doesn't make any sense without a place of that time measurement.
  Therefore there is no implicit origin conversion possible here,
  and managing the place of measurement is left to the client code.
  """

  alias XestClock.Time

  # Note : The interval represented is a time interval -> continuous
  # EVEN IF the encoding interval is discrete (integer)
  # TODO : check https://github.com/kipcole9/tempo

  @enforce_keys [:unit, :interval]
  defstruct interval: nil,
            unit: nil

  @typedoc "Timeinterval struct"
  @type t() :: %__MODULE__{
          interval: Interval.t(),
          unit: System.time_unit()
        }

  @doc """
  Builds a time interval from two timestamps.
    right and left are determined by comparing the two timestamps
  """
  def build(%Time.Value{} = ts1, %Time.Value{} = ts2) do
    cond do
      ts1.unit != ts2.unit ->
        raise(ArgumentError, message: "time bounds unit mismatch ")

      ts1.value == ts2.value ->
        raise(ArgumentError, message: "time bounds identical. interval would be empty...")

      ts1.value < ts2.value ->
        %__MODULE__{
          unit: ts1.unit,
          interval:
            Interval.new(
              module: Interval.Integer,
              left: ts1.value,
              right: ts2.value,
              bounds: "[)"
            )
        }

      ts1.value > ts2.value ->
        %__MODULE__{
          unit: ts1.unit,
          interval:
            Interval.new(
              module: Interval.Integer,
              left: ts2.value,
              right: ts1.value,
              bounds: "[)"
            )
        }
    end
  end

  # TODO : validate time unit ??
end

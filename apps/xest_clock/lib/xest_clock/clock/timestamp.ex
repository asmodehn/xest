defmodule XestClock.Clock.Timestamp do
  @docmodule """
  The `XestClock.Clock.Timestamp` module deals with timestamp struct.
  This struct can store one timestamp.

  Note: time measurement doesn't make any sense without a place of that time measurement.
  Therefore there is no implicit origin conversion possible here,
  and managing the place of measurement is left to the client code.
  """

  @enforce_keys [:origin, :unit, :ts]
  defstruct ts: nil,
            unit: nil,
            origin: nil

  @typedoc "XestClock.Clock.Timestamp struct"
  @type t() :: %__MODULE__{
          ts: integer(),
          unit: System.time_unit(),
          origin: atom()
        }

  @spec new(atom(), System.time_unit(), integer()) :: t()
  def new(origin, unit, ts) do
    %__MODULE__{
      # TODO : should be an already known atom...
      origin: origin,
      # TODO : normalize unit (clock ? not private ?)
      unit: unit,
      ts: ts
    }
  end
end

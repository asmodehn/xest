defmodule XestClock.Clock.Timestamps do
  @docmodule """
  The `XestClock.Clock.Timestamps` module deals with timestamp struct.
  This struct can store one or more timestamps from the same origin, with the same unit of measurement.

  Unit and origin mismatch immediately triggers an exception.
  Note: unit conversion could be done, but would require Arbitrary-Precision Arithmetic
   -> see https://github.com/Vonmo/eapa

  Note: time measurement doesn't make any sense without a place of that time measurement.
  Therefore there is no implicit origin conversion possible here,
  and managing the place of measurement is left to the client code.
  """

  @enforce_keys [:origin, :unit, :tss]
  defstruct tss: nil,
            unit: nil,
            origin: nil

  @typedoc "Timestamps struct"
  @type t() :: %__MODULE__{
          # TODO : is the list actually useful here ???
          tss: [integer()],
          unit: System.time_unit(),
          origin: atom()
        }

  @spec new(atom(), System.time_unit(), [integer()]) :: Timestamps
  def new(origin, unit, tss) do
    %__MODULE__{
      # TODO : should be an already known atom...
      origin: origin,
      # TODO : normalize unit (clock ? not private ?)
      unit: unit,
      # TODO : list as monad implementation (only writer)
      tss: tss
    }
  end

  # TODO : ++ concat with other...
  # Maybe Already handled by collectible / enumerable ?

  # TODO : Enumerable (matching origin and unit)
  # TODO : Collectable
end

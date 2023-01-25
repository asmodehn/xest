defmodule XestClock.Stream.Timed.LocalStamp do
  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System

  @enforce_keys [:unit, :monotonic, :vm_offset]
  defstruct unit: nil,
            monotonic: nil,
            vm_offset: nil

  @typedoc "LocalStamp struct"
  @type t() :: %__MODULE__{
          unit: System.time_unit(),
          monotonic: integer(),
          vm_offset: integer()
        }

  def now(unit) do
    %__MODULE__{
      unit: unit,
      monotonic: System.monotonic_time(unit),
      vm_offset: System.time_offset(unit)
    }
  end

  # return type ? the offset doesnt have much meaning, but we need the unit...
  @spec diff(t(), t()) :: t()
  def diff(%__MODULE__{} = a, %__MODULE__{} = b) do
    if System.convert_time_unit(1, a.unit, b.unit) < 1 do
      # invert conversion to avoid losing precision
      %__MODULE__{
        monotonic: a.monotonic - System.convert_time_unit(b.monotonic, b.unit, a.unit),
        unit: a.unit,
        vm_offset: nil
        # div(a.vm_offset + System.convert_time_unit(b.vm_offset, b.unit, a.unit), 2)
      }

      #            # TMP averaging the offset as a first approximation for derivation,
      ##            until we have a need for something more solid...
      ## This is currently fine, since for simple duration semantics the offset is unused.
    else
      %__MODULE__{
        monotonic: System.convert_time_unit(a.monotonic, a.unit, b.unit) - b.monotonic,
        unit: b.unit,
        vm_offset: nil

        # div(System.convert_time_unit(a.vm_offset, a.unit, b.unit) + b.vm_offset, 2)
      }

      #            # TMP averaging the offset as a first approximation for derivation,
      ##            until we have a need for something more solid...
      ## This is currently fine, since for simple duration semantics the offset is unused.
    end
  end
end

defmodule XestClock.Stream.Timed do
  @moduledoc """
    A module to deal with stream that have a time constraint
  """

  alias XestClock.System

  defmodule LocalStamp do
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
      %LocalStamp{
        unit: unit,
        monotonic: System.monotonic_time(unit),
        vm_offset: System.time_offset(unit)
      }
    end

    # return type ? the offset doesnt have much meaning, but we need the unit...
    @spec diff(t(), t()) :: t()
    def diff(%LocalStamp{} = a, %LocalStamp{} = b) do
      if System.convert_time_unit(1, a.unit, b.unit) < 1 do
        # invert conversion to avoid losing precision
        %LocalStamp{
          monotonic: a.monotonic - System.convert_time_unit(b.monotonic, b.unit, a.unit),
          unit: a.unit,
          vm_offset: nil
          # div(a.vm_offset + System.convert_time_unit(b.vm_offset, b.unit, a.unit), 2)
        }

        #            # TMP averaging the offset as a first approximation for derivation,
        ##            until we have a need for something more solid...
        ## This is currently fine, since for simple duration semantics the offset is unused.
      else
        %LocalStamp{
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

    #        def since(%LocalStamp{unit: unit, monotonic: monotonic, vm_offset: vm_offset}) do
    #          %LocalStamp {
    #          unit: unit,
    #          monotonic: System.monotonic_time(unit) - monotonic,
    #          vm_offset: (System.time_offset(unit) + vm_offset) / 2
    #            # TMP averaging the offset as a first approximation for derivation,
    ##            until we have a need for something more solid...
    ## This is currently fine, since for simple duration semantics the offset is unused.
    #          }

    #        end
  end

  @spec timed(Enumerable.t(), System.time_unit()) :: Enumerable.t()
  def timed(enum, precision \\ System.native_time_unit())

  def timed(enum, precision) when is_atom(precision) do
    case precision do
      :second -> timed(enum, 1)
      :millisecond -> timed(enum, 1_000)
      :microsecond -> timed(enum, 1_000_000)
      :nanosecond -> timed(enum, 1_000_000_000)
    end
  end

  def timed(enum, precision) when is_integer(precision) do
    # Note: unit is defined before computation in stream, and the same for all elements.
    best_unit =
      cond do
        precision <= 1 -> :second
        precision <= 1_000 -> :millisecond
        precision <= 1_000_000 -> :microsecond
        precision <= 1_000_000_000 -> :nanosecond
      end

    Enum.map(enum, fn
      elem -> {elem, LocalStamp.now(best_unit)}
    end)
  end

  def untimed(enum) do
    Enum.map(enum, fn
      {original_elem, %LocalStamp{}} -> original_elem
    end)
  end
end

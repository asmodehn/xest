defmodule XestClock.Stream.Timed.LocalStamp do
  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System
  alias XestClock.TimeValue

  @enforce_keys [:monotonic]
  defstruct monotonic: nil,
            unit: nil,
            vm_offset: nil

  @typedoc "LocalStamp struct"
  @type t() :: %__MODULE__{
          monotonic: TimeValue.t(),
          unit: System.time_unit(),
          vm_offset: integer()
        }

  def now(unit) do
    %__MODULE__{
      unit: unit,
      monotonic: TimeValue.new(unit, System.monotonic_time(unit)),
      vm_offset: System.time_offset(unit)
    }
  end

  def with_previous(%__MODULE__{} = recent, %__MODULE__{} = past) do
    %{recent | monotonic: recent.monotonic |> TimeValue.with_derivatives_from(past.monotonic)}
  end

  # return type ? the offset doesnt have much meaning, but we need the unit...
  @spec diff(t(), t()) :: t()
  def diff(%__MODULE__{} = a, %__MODULE__{} = b) do
    # TODO : get rid of this ?? since we have time VAlue we dont need it any longer.
    %__MODULE__{
      unit: a.unit,
      monotonic: TimeValue.with_derivatives_from(a, b),
      vm_offset: a.vm_offset
    }
  end
end

defimpl String.Chars, for: XestClock.Stream.Timed.LocalStamp do
  def to_string(%XestClock.Stream.Timed.LocalStamp{
        monotonic: tv,
        unit: _unit,
        vm_offset: vm_offset
      }) do
    # TODO: maybe have a more systematic / global way to manage time unit ??
    # to something that is immediately parseable ? some sigil ??
    # some existing physical unit library ?

    # delegating to TimeValue... good or bad idea ?
    "#{%{tv | monotonic: tv.monotonic + vm_offset}}"
  end
end

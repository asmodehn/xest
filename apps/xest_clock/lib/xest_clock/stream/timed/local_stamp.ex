defmodule XestClock.Stream.Timed.LocalStamp do
  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System
  alias XestClock.Time

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
      monotonic: Time.Value.new(unit, System.monotonic_time(unit)),
      vm_offset: System.time_offset(unit)
      # TODO : how can we force vm_offset to always be same unit as monotonic ??
    }
  end

  @spec system_time(t()) :: Time.Value.t()
  def system_time(%__MODULE__{} = lts) do
    %{lts.monotonic | value: lts.monotonic.value + lts.vm_offset}
  end

  def elapsed_since(%__MODULE__{} = lts, %__MODULE__{} = previous_lts) do
    Time.Value.diff(
      system_time(lts),
      system_time(previous_lts)
    )
  end

  def convert(%__MODULE__{} = lts, unit) do
    nu = System.Extra.normalize_time_unit(unit)

    %__MODULE__{
      unit: nu,
      monotonic: lts.monotonic |> Time.Value.convert(nu),
      vm_offset: Time.Value.new(lts.unit, lts.vm_offset) |> Time.Value.convert(nu)
      # TODO : how can we force vm_offset to always be same unit as monotonic ??
      # maybe make vm_offset also a time value ??
    }
  end

  #  Lets get rid of that, the user can doit in its transform...
  #  def with_previous(%__MODULE__{} = recent, %__MODULE__{} = past) do
  #    %{
  #      recent
  #      | monotonic: recent.monotonic |> XestClock.Time.Value.with_previous(past.monotonic)
  #    }
  #  end

  # UNEEDED any longer ?
  # return type ? the offset doesnt have much meaning, but we need the unit...
  #  @spec diff(t(), t()) :: t()
  #  def diff(%__MODULE__{} = a, %__MODULE__{} = b) do
  #    # TODO : get rid of this ?? since we have time VAlue we dont need it any longer.
  #    %__MODULE__{
  #      unit: a.unit,
  #      monotonic: XestClock.TimeValue.with_derivatives_from(a, b),
  #      vm_offset: a.vm_offset
  #    }
  #  end
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
    "#{%{tv | monotonic: tv.value + vm_offset}}"
  end
end

defmodule XestClock.Stream.Timed.LocalStamp do
  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System
  # hiding Elixir.Process to make sure we do not inadvertently use it
  alias XestClock.Process

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

  def now(unit \\ System.Extra.native_time_unit()) do
    %__MODULE__{
      unit: unit,
      monotonic: System.monotonic_time(unit),
      vm_offset: System.time_offset(unit)
    }
  end

  @spec as_timevalue(t()) :: Time.Value.t()
  def as_timevalue(%__MODULE__{} = lts) do
    Time.Value.new(lts.unit, lts.monotonic + lts.vm_offset)
  end

  @spec system_time(t(), System.time_unit()) :: Time.Value.t()
  def system_time(%__MODULE__{} = lts, unit) do
    as_timevalue(lts)
    |> Time.Value.convert(unit)
  end

  @spec monotonic_time(t()) :: Time.Value.t()
  def monotonic_time(%__MODULE__{} = lts) do
    Time.Value.new(lts.unit, lts.monotonic)
  end

  @spec time_offset(t()) :: Time.Value.t()
  def time_offset(%__MODULE__{} = lts) do
    Time.Value.new(lts.unit, lts.vm_offset)
  end

  @spec monotonic_time(t(), System.time_unit()) :: Time.Value.t()
  def monotonic_time(%__MODULE__{} = lts, unit) do
    monotonic_time(lts)
    |> Time.Value.convert(unit)
  end

  @spec time_offset(t(), System.time_unit()) :: Time.Value.t()
  def time_offset(%__MODULE__{} = lts, unit) do
    time_offset(lts)
    |> Time.Value.convert(unit)
  end

  def elapsed_since(%__MODULE__{} = lts, %__MODULE__{} = previous_lts)
      when lts.unit == previous_lts.unit do
    Time.Value.new(
      lts.unit,
      lts.monotonic + lts.vm_offset - previous_lts.monotonic - previous_lts.vm_offset
    )
  end

  def after_a_while(%__MODULE__{} = lts, %Time.Value{} = tv) do
    converted_tv = Time.Value.convert(tv, lts.unit)

    %__MODULE__{
      unit: lts.unit,
      # guessing monotonic value then. remove possible error to be conservative.
      monotonic: lts.monotonic + converted_tv.value - converted_tv.error,
      # just a guess
      vm_offset: lts.vm_offset
    }
  end

  def middle_stamp_estimate(%__MODULE__{} = lts_before, %__MODULE__{} = lts_after)
      when lts_before.unit == lts_after.unit do
    %__MODULE__{
      unit: lts_before.unit,
      # we use floor_div here to always round downwards (no matter where 0 happens to be)
      # monotonic constraints should be set on the stream to avoid time going backwards
      monotonic: Integer.floor_div(lts_before.monotonic + lts_after.monotonic, 2),
      # CAREFUL: we loose precision and introduce errors here...
      # AND we suppose the vm offset only changes linearly...
      vm_offset: Integer.floor_div(lts_before.vm_offset + lts_after.vm_offset, 2)
      # BUT we are NOT interested in tracking error in local timestamps.
    }
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

  @spec wake_up_at(t()) :: t()
  def wake_up_at(%__MODULE__{} = lts) do
    bef = now(lts.unit)

    # difference (ms)
    to_wait =
      System.convert_time_unit(lts.monotonic, lts.unit, :millisecond) -
        System.convert_time_unit(bef.monotonic, bef.unit, :millisecond)

    # SIDE_EFFECT !
    # and always return current timestamp, since we have to measure it anyway...
    if to_wait > 0 do
      Process.sleep(to_wait)
      now(lts.unit)
    else
      # lets avoid another probably useless System call
      bef
    end
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
    "#{%{tv | monotonic: tv.value + vm_offset}}"
  end
end

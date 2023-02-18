defmodule XestClock.Time.Extra do
  @moduledoc """
      This module holds Extra functionality that is needed by XestClock.Time,
    but not present, or not exposed in Elixir.Time
  """

  #  @behaviour XestClock.Time.ExtraBehaviour

  @spec value(System.time_unit(), integer) :: XestClock.TimeValue
  def value(unit, value) do
    XestClock.Time.Value.new(unit, value)
  end

  def local_offset(unit) do
    value(unit, XestClock.System.time_offset(unit))
  end

  def stamp(System, unit) do
    %XestClock.Stream.Timed.LocalStamp{
      # TODO get rid of it, once we call local_offset
      unit: unit,
      monotonic: XestClock.Time.Value.new(unit, System.monotonic_time(unit)),
      # TODO use local_offset
      vm_offset: XestClock.System.time_offset(unit)
    }
  end

  def stamp(origin, unit, value) do
    # TODO : improve how we handle origin (module atom, pid, etc...)
    XestClock.Time.Stamp.new(origin, unit, value)
  end
end

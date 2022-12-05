defmodule XestClock.Clock.Local do
  @docmodule """
  Managing function specific to local (or local-relative) clocks
  """

  alias XestClock.Clock.Timeunit
  require XestClock.Timestamp

  @spec timestamp(atom(), System.time_unit(), integer()) :: XestClock.Timestamp.t()
  def timestamp(origin, unit, ts) do
    XestClock.Timestamp.new(
      origin,
      unit,
      # Adding time offset as ts should be from monotone_time
      ts + System.time_offset(unit)
    )
  end
end

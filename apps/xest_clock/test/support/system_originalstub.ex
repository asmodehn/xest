defmodule XestClock.System.OriginalStub do
  @behaviour XestClock.System.OriginalBehaviour

  @impl true
  @doc "stub implementation of **impure** monotone_time/3 of XestClock.System.OriginalBehaviour"
  def monotonic_time(_unit) do
    raise XestClock.TestExceptions.Impure
  end

  @impl true
  @doc "stub implementation of **impure** time_offset/3 of XestClock.System.OriginalBehaviour"
  def time_offset(_unit) do
    raise XestClock.TestExceptions.Impure
  end

  @impl true
  @doc "stub implementation of pure convert_time_unit/3 of XestClock.System.OriginalBehaviour"
  defdelegate convert_time_unit(time, from_unit, to_unit), to: System

  # Note : no stub implementation of impure function when that can be avoided (let the Mock fail)
  # Like for native_time_unit/0
end

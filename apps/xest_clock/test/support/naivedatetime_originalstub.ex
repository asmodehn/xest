defmodule XestClock.NaiveDateTime.OriginalStub do
  @behaviour XestClock.NaiveDateTime.OriginalBehaviour

  @impl true
  @doc "stub implementation of **impure** utc_now/3 of XestClock.DateTime.OriginalBehaviour"
  def utc_now(_calendar \\ Calendar.ISO) do
    raise XestClock.TestExceptions.Impure
  end
end

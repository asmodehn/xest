defmodule XestClock.NewWrapper.DateTime.OriginalStub do
  @behaviour XestClock.NewWrapper.DateTime.OriginalBehaviour

  @impl true
  @doc "stub implementation of **impure** utc_now/3 of XestClock.DateTime.OriginalBehaviour"
  def utc_now(_calendar \\ Calendar.ISO) do
    raise XestClock.TestExceptions.Impure
  end

  @impl true
  @doc "stub implementation of pure from_unix/3 of XestClock.DateTime.OriginalBehaviour"
  defdelegate from_unix(integer, unit \\ :second, calendar \\ Calendar.ISO), to: DateTime

  @impl true
  @doc "stub implementation of pure from_unix!/3 of XestClock.DateTime.OriginalBehaviour"
  defdelegate from_unix!(integer, unit \\ :second, calendar \\ Calendar.ISO), to: DateTime

  @impl true
  @doc "stub implementation of pure to_naive/1 of XestClock.DateTime.OriginalBehaviour"
  defdelegate to_naive(calendar_datetime), to: DateTime
end

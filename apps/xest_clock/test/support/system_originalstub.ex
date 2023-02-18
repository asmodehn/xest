defmodule XestClock.System.OriginalStub do
  @behaviour XestClock.System.OriginalBehaviour

  @impl true
  @doc """
    stub implementation of **impure** monotone_time/3 of XestClock.System.OriginalBehaviour.
    Used to replace mocks when running doctests.
  """
  defdelegate monotonic_time(unit), to: Elixir.System

  @impl true
  @doc """
    stub implementation of **impure** time_offset/3 of XestClock.System.OriginalBehaviour.
    Used to replace mocks when running doctests.
  """
  defdelegate time_offset(unit), to: Elixir.System

  # Note : the only useful stub implementation are redefinition of impure function, but their use should be limited to doctests,
  # when the outputs or sideeffects are not relevant, yet we dont want to pollute docs with Hammox.expect() calls.
end

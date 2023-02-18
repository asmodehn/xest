defmodule XestClock.System.ExtraStub do
  @behaviour XestClock.System.ExtraBehaviour

  @impl true
  @doc """
    stub implementation of **impure** monotone_time/3 of XestClock.System.OriginalBehaviour.
    Used to replace mocks when running doctests.
  """
  defdelegate native_time_unit(), to: XestClock.System.Extra

  # Note : the only useful stub implementation are redefinition of impure function, but their use should be limited to doctests,
  # when the outputs or side effects are not relevant, yet we dont want to pollute docs with Hammox.expect() calls.
end

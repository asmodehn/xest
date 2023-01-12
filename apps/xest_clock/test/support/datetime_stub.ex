defmodule XestClock.DateTime.Stub do
  @behaviour XestClock.DateTime.Behaviour

  # harcoding stub to refer to datetime.

  @impl true
  def new() do
    # return epoch by default
    DateTime.from_unix!(0)
  end

  @impl true
  defdelegate utc_now(), to: DateTime
end

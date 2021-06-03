defmodule Xest.DateTime.Behaviour do
  # This is mandatory to use in Algebraic types
  @callback new :: DateTime.t()

  # This is the most useful effectful function
  @callback utc_now :: DateTime.t()
end

defmodule Xest.DateTime do
  @behaviour Xest.DateTime.Behaviour

  @impl true
  def new() do
    # return epoch by default
    date_time().from_unix!(0)
  end

  @impl true
  def utc_now() do
    date_time().utc_now()
  end

  defp date_time(), do: Application.get_env(:xest, :date_time_module, DateTime)
end

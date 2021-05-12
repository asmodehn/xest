# the behaviour
defmodule Xest.DateTime.Behaviour do
  @callback utc_now :: DateTime.t()
end

# the Utils Module
defmodule Xest.DateTime do
  @behaviour Xest.DateTime.Behaviour

  @impl true
  def utc_now() do
    date_time().utc_now()
  end

  defp date_time(), do: Application.get_env(:xest, :date_time_module, DateTime)
end

defmodule Xest.BinanceServer.Stub do
  @moduledoc """
    Since the Binance Client GenServer might call things "internally",
    like calling ping periodically for instance,
    we need a stub implementation of the API_Behavior to implement these on adapter mocks
  """

  @behaviour Xest.Ports.BinanceServerBehaviour

  alias Xest.Models.ExchangeStatus

  @impl true
  def system_status(_pid), do: {:ok, %ExchangeStatus{}}

  @impl true
  def time(_pid), do: {:ok, DateTime.utc_now()}
end

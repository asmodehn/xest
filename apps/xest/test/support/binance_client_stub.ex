defmodule Xest.BinanceClient.Stub do
  @moduledoc """
    Since the Binance Client GenServer might call things "internally",
    like calling ping periodically for instance,
    we need a stub implementation of the API_Behavior to implement these on adapter mocks
  """

  @behaviour Xest.Ports.BinanceClientBehaviour

  @impl true
  def ping(), do: {:ok, %{}}

  @impl true
  def system_status(), do: {:ok, %{"msg" => "normal", "status" => 0}}

  @impl true
  def time(), do: {:ok, %{"serverTime" => 1_613_638_412_313}}
end

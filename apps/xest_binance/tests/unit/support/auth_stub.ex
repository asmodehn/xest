defmodule XestBinance.Auth.Stub do
  @moduledoc """
    Since the Binance Client GenServer might call things "internally",
    like calling ping periodically for instance,
    we need a stub implementation of the API_Behavior to implement these on adapter mocks
  """

  @behaviour XestBinance.Auth.Behaviour

  @impl true
  def account(_pid), do: {:ok, %Binance.Account{}}

  @impl true
  def account!(pid \\ __MODULE__) do
    {:ok, response} = account(pid)
    response
  end

  @impl true
  def trades(_pid, _symbol), do: {:ok, []}

  @impl true
  def trades!(pid \\ __MODULE__, _symbol) do
    {:ok, response} = account(pid)
    response
  end
end

defmodule XestBinance.Auth.Stub do
  @moduledoc """
    Since the Binance Client GenServer might call things "internally",
    like calling ping periodically for instance,
    we need a stub implementation of the API_Behavior to implement these on adapter mocks
  """

  @behaviour XestBinance.Auth.Behaviour

  alias XestBinance.Models.Account

  @impl true
  def account(_pid), do: {:ok, %Account{}}

  @impl true
  def account!(pid \\ __MODULE__) do
    {:ok, response} = account(pid)
    response
  end
end

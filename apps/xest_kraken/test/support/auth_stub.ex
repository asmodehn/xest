defmodule XestKraken.Auth.Stub do
  @moduledoc """
    Since the Kraken Client GenServer might call things "internally",
    like calling ping periodically for instance,
    we need a stub implementation of the API_Behavior to implement these on adapter mocks
  """

  @behaviour XestKraken.Auth.Behaviour

  @impl true
  def balance(_pid), do: {:ok, %XestKraken.Account.Balance{}}

  @impl true
  def balance!(pid \\ __MODULE__) do
    {:ok, response} = balance(pid)
    response
  end
end

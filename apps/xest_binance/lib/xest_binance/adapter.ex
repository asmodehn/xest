defmodule XestBinance.Adapter do
  @moduledoc """
  This module implements the anticorruption layer between the adapter
  and our internal kraken data representation.

    It converts between whatever adapter chose as representation to our own.

  """
  alias XestBinance.Exchange
  alias XestBinance.Adapter.Client

  @default_endpoint "https://api.binance.com"

  defp implementation() do
    Application.get_env(:xest_binance, :adapter, XestBinance.Adapter.Binance)
  end

  defdelegate client(apikey \\ nil, secret \\ nil, endpoint \\ @default_endpoint),
    to: Client,
    as: :new

  @spec system_status(Client.t()) :: Exchange.Status.t()
  def system_status(%Client{} = cl \\ client()) do
    {:ok, status} = implementation().system_status(cl)
    Exchange.Status.new(status)
  end

  @spec servertime(Client.t()) :: Exchange.ServerTime.t()
  def servertime(%Client{} = cl \\ client()) do
    {:ok, servertime} = implementation().servertime(cl)
    Exchange.ServerTime.new(%{servertime: servertime})
  end

  def account(%Client{} = cl) do
    implementation().account(cl)
    # TODO : wrap into common xest type...
  end
end

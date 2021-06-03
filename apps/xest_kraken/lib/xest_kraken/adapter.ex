defmodule XestKraken.Adapter do
  @moduledoc """
  This module implements the anticorruption layer between the adapter
  and our internal kraken data representation.

    It converts between whatever adapter chose as representation to our own.

  """
  alias XestKraken.Exchange
  alias XestKraken.Adapter.Client

  defp implementation() do
    Application.get_env(:xest_kraken, :adapter, XestKraken.Adapter.Krakex)
  end

  @spec system_status(Client.t()) :: Exchange.Status.t()
  def system_status(%Client{} = client \\ Client.new()) do
    {:ok, status} = implementation().system_status(client)
    Exchange.Status.new(status)
  end

  @spec servertime(Client.t()) :: Exchange.ServerTime.t()
  def servertime(%Client{} = client \\ Client.new()) do
    {:ok, servertime} = implementation().servertime(client)
    Exchange.ServerTime.new(servertime)
  end
end

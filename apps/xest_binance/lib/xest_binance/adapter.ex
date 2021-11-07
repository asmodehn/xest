defmodule XestBinance.Adapter do
  @moduledoc """
  This module implements the anticorruption layer between the adapter
  and our internal kraken data representation.

    It converts between whatever adapter chose as representation to our own.

  """
  alias XestBinance.Exchange
  alias XestBinance.Adapter.Client

  @default_endpoint "https://api.binance.com"

  defdelegate client(apikey \\ nil, secret \\ nil, endpoint \\ @default_endpoint),
    to: Client,
    as: :new

  alias XestBinance.Adapter.Cache
  use Nebulex.Caching

  @spec system_status(Client.t()) :: Exchange.Status.t()
  @decorate cacheable(cache: Cache, key: :system_status, opts: [ttl: :timer.minutes(1)])
  def system_status(%Client{} = cl \\ client()) do
    {:ok, status} = cl.adapter.system_status(cl)
    Exchange.Status.new(status)
  end

  @spec servertime(Client.t()) :: Exchange.ServerTime.t()
  # no caching here to avoid timing issues on local proxy clock
  def servertime(%Client{} = cl \\ client()) do
    {:ok, servertime} = cl.adapter.servertime(cl)
    Exchange.ServerTime.new(%{servertime: servertime})
  end

  # maybe useless ?? we could use the status for this...
  def ping(%Client{} = cl \\ client()) do
    {:ok, resp} = cl.adapter.ping(cl)
    resp
  end

  def account(%Client{} = cl) do
    cl.adapter.account(cl)
    # TODO : wrap into common xest type...
  end

  def trades(%Client{} = cl \\ client(), symbol) when is_binary(symbol) do
    cl.adapter.trades(cl, symbol)
  end
end

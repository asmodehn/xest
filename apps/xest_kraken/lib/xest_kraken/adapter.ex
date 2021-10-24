defmodule XestKraken.Adapter do
  @moduledoc """
  This module implements the anticorruption layer between the adapter
  and our internal kraken data representation.

    It converts between whatever adapter chose as representation to our own.

  """
  alias XestKraken.Exchange
  alias XestKraken.Adapter.Client

  @default_endpoint "https://api.kraken.com"

  defdelegate client(apikey \\ nil, secret \\ nil, endpoint \\ @default_endpoint),
    to: Client,
    as: :new

  alias XestKraken.Adapter.Cache
  use Nebulex.Caching

  @spec system_status(Client.t()) :: Exchange.Status.t()
  @decorate cacheable(cache: Cache, key: :system_status, opts: [ttl: :timer.minutes(1)])
  def system_status(%Client{} = client \\ Client.new()) do
    {:ok, status} = client.adapter.system_status(client)
    # TODO : handle {:error, :nxdomain}
    Exchange.Status.new(status)
  end

  @spec servertime(Client.t()) :: Exchange.ServerTime.t()
  # no cache here to not interfere with the local clock proxy agent
  def servertime(%Client{} = client \\ Client.new()) do
    {:ok, servertime} = client.adapter.servertime(client)
    Exchange.ServerTime.new(servertime)
  end

  def balance(%Client{} = cl) do
    cl.adapter.balance(cl)
    # TODO : wrap into some connector specific type...
  end
end
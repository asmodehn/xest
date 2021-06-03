defmodule Xest.Exchange do
  def status(:kraken) do
    Xest.Exchange.Adapter.retrieve(:kraken, :status)
  end

  def status(:binance) do
    Xest.Exchange.Adapter.retrieve(:binance, :status)
  end

  def servertime(connector) do
    Xest.Exchange.Adapter.retrieve(connector, :servertime)
  end
end

defmodule Xest.Exchange.Adapter do
  defp kraken() do
    Application.get_env(:xest, :kraken_exchange)
  end

  defp binance() do
    Application.get_env(:xest, :binance_exchange)
  end

  def retrieve(:kraken, :status) do
    connector_response = kraken().status(Process.whereis(kraken()))

    Xest.Exchange.Status.ACL.new(connector_response)
  end

  def retrieve(:binance, :status) do
    connector_response = binance().status(Process.whereis(binance()))

    Xest.Exchange.Status.ACL.new(connector_response)
  end

  def retrieve(:binance, :servertime) do
    response = binance().servertime(Process.whereis(binance()))

    Xest.Exchange.ServerTime.ACL.new(response)
  end

  def retrieve(:kraken, :servertime) do
    response = kraken().servertime(Process.whereis(kraken()))

    Xest.Exchange.ServerTime.ACL.new(response)
  end
end

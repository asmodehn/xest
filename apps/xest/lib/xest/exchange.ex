defmodule Xest.Exchange do
  def status(:kraken) do
    Xest.Exchange.Adapter.retrieve(:kraken, :status)
  end

  # TODO : binance version (and get rid of exchange_status.ex)
end

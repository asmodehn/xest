defmodule Xest.Exchange do
  defmodule Behaviour do
    @moduledoc "Behaviour to allow mocking a xest exchange for tests"
    @callback status(atom()) :: %Xest.Exchange.Status{}
    @callback servertime(atom()) :: %Xest.Exchange.ServerTime{}
  end

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

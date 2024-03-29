defmodule Xest.Exchange do
  defmodule Behaviour do
    @moduledoc "Behaviour to allow mocking a xest exchange for tests"
    @callback status(atom()) :: %Xest.Exchange.Status{}
    @callback servertime(atom()) :: %Xest.Exchange.ServerTime{}
    @callback symbols(atom()) :: [String.t()]
  end

  def status(connector) do
    Xest.Exchange.Adapter.retrieve(connector, :status)
  end

  def servertime(connector) do
    Xest.Exchange.Adapter.retrieve(connector, :servertime)
  end

  def symbols(connector) do
    Xest.Exchange.Adapter.retrieve(connector, :symbols)
  end
end

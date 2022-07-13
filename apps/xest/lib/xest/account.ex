defmodule Xest.Account do
  @moduledoc """
    defines an account structure with ADT
  """

  defmodule Behaviour do
    @moduledoc "Behaviour to allow mocking a xest account for tests"
    @callback balance(atom()) :: %Xest.Account.Balance{}
    @callback transactions(atom(), String.t()) :: %Xest.Account.TradesHistory{}
  end

  def balance(connector) do
    Xest.Account.Adapter.retrieve(connector, :balance)
  end

  def transactions(connector, symbol) do
    Xest.Account.Adapter.retrieve(connector, :trades, symbol)
  end
end

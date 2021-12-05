defmodule Xest.Account.Trade do
  import Algae

  @moduledoc """
    defines an asset balance with ADT
  """

  defdata do
    pair :: String.t()
    price :: float()
    time :: float()
    vol :: float()
    #    cost :: float()
    #    fee :: float()
    #    margin :: float()
    #    misc :: String.t()
    #    ordertxid :: String.t()
    #    ordertype :: String.t()
    #    postxid :: String.t()
    #    type :: String.t()
  end
end

# Protocol for each connector to provide an exchange status with the correct format
defprotocol Xest.Account.Trade.ACL do
  @spec new(t) :: Xest.Account.Trade.t()
  def new(trade)
end

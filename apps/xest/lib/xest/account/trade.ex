defmodule Xest.Account.Trade do
  import Algae

  @moduledoc """
    defines an asset balance with ADT
  """

  defdata do
    cost :: float()
    fee :: float()
    margin :: float()
    misc :: String.t()
    ordertxid :: String.t()
    ordertype :: String.t()
    pair :: String.t()
    postxid :: String.t()
    price :: float()
    time :: float()
    type :: String.t()
    vol :: float()
  end
end

# Protocol for each connector to provide an exchange status with the correct format
defprotocol Xest.Account.Trade.ACL do
  @spec new(t) :: Xest.Account.Trade.t()
  def new(asset)
end

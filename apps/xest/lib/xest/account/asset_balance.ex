defmodule Xest.Account.AssetBalance do
  import Algae

  @moduledoc """
    defines an asset balance with ADT
  """

  defdata do
    asset :: String.t()
    # TODO : find proper numeric representation for these
    free :: String.t() \\ "0.0"
    locked :: String.t() \\ "0.0"
  end
end

# Protocol for each connector to provide an exchange status with the correct format
defprotocol Xest.Account.AssetBalance.ACL do
  @spec new(t) :: Xest.Account.AssetBalance.t()
  def new(asset)
end

defmodule Xest.Account.Balance do
  import Algae

  @moduledoc """
    defines a balance structure with ADT
  """

  defdata do
    balances :: [Xest.Account.AssetBalance.t()]
    # available in binance but not kraken ??
    # is request time (local)  should probably not be used to emulate actual (remote) time.
    #    update_time :: DateTime.t() \\ ~U[1970-01-01 00:00:00Z]
  end

  # TODO : by default new() for list should always convert list content to AssetBalance if needed (?)
end

# Protocol for each connector to provide an exchange status with the correct format
defprotocol Xest.Account.Balance.ACL do
  @spec new(t) :: Xest.Account.Balance.t()
  def new(value)
end

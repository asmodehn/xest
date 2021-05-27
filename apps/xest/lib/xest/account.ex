defmodule Xest.Account do
  import Algae

  @moduledoc """
    defines an account structure with ADT
  """

  defdata do
    balances :: [Account.AssetBalance.t()]
    maker_commission :: non_neg_integer()
    taker_commission :: non_neg_integer()
    buyer_commission :: non_neg_integer()
    seller_commission :: non_neg_integer()
    can_trade :: boolean()
    can_withdrawal :: boolean()
    can_deposit :: boolean()
    update_time :: DateTime.t() \\ ~U[1970-01-01 00:00:00Z]
    # not exposed by binance.ex ?
    account_type :: String.t()
    # not exposed by binance.ex ?
    permissions :: [String.t()]
  end
end

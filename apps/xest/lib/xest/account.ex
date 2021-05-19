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
    # this \\ DateTime.utc_now() default doesnt work because of DateTime.new()
    update_time :: DateTime.t() \\ ~U[1970-01-01 00:00:00Z]
    account_type :: String.t()
    permissions :: [String.t()]
  end
end

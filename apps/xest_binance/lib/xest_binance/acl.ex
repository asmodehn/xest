defmodule XestBinance.ACL do
  @moduledoc """
    Acts as an Anti-corruption layer,
   providing functions to translate from the Binance model into the Xest model
  and vice-versa
  """

  require Binance
  require Xest

  def to_xest(%Binance.Account{} = binance) do
    Xest.Account.new(
      binance.balances,
      binance.maker_commission,
      binance.taker_commission,
      binance.buyer_commission,
      binance.seller_commission,
      binance.can_trade,
      binance.can_withdrawl,
      binance.can_deposit,
      binance.update_time
      #    binance.account_type,
      #    binance.permissions
    )
  end

  def to_xest(%Binance.SystemStatus{} = binance) do
    Xest.ExchangeStatus.new(
      binance.status,
      binance.msg
    )
  end

  #  def to_binance() do
  #
  #    end
end

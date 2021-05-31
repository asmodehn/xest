defmodule XestKraken.ACL do
  @moduledoc """
    Acts as an Anti-corruption layer,
   providing functions to translate from the Binance model into the Xest model
  and vice-versa
  """

  require Xest

  #  def to_xest(%Binance.Account{} = binance) do
  #    Xest.Account.new(
  #      binance.balances,
  #      binance.maker_commission,
  #      binance.taker_commission,
  #      binance.buyer_commission,
  #      binance.seller_commission,
  #      binance.can_trade,
  #      binance.can_withdrawl,
  #      binance.can_deposit,
  #      binance.update_time
  #      #    binance.account_type,
  #      #    binance.permissions
  #    )
  #  end

  def to_xest(%XestKraken.Adapter.SystemStatus{} = krakex_status) do
    Xest.ExchangeStatus.new(
      if(krakex_status.status == "normal", do: 0, else: 1),
      krakex_status.status
    )
  end

  #  def from_xest() do
  #
  #    end
end

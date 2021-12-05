defmodule XestBinance.Account.Trades.Test do
  use ExUnit.Case
  use ExUnitProperties

  def binance_trade_generator() do
    %{
      commission: StreamData.float(min: 0.0),
      commissionAsset: StreamData.string(Enum.concat([?A..?Z])),
      id: StreamData.string(:alphanumeric),
      isBestMatch: StreamData.boolean(),
      isBuyer: StreamData.boolean(),
      isMaker: StreamData.boolean(),
      orderId: StreamData.string(:alphanumeric),
      orderListId: StreamData.string(:alphanumeric),
      price: StreamData.float(min: 0.0),
      qty: StreamData.float(min: 0.0),
      quoteQty: StreamData.float(min: 0.0),
      symbol: StreamData.string(Enum.concat([?A..?Z])),
      time: StreamData.integer(0..System.system_time())
    }
    |> StreamData.fixed_map()
    |> StreamData.map(&Binance.Trade.new/1)
  end

  describe "new/1" do
    property "generates a Binance.Trade and convert it to a Xest.Account.Trade using the ACL protocol" do
      check all(btd <- binance_trade_generator()) do
        xtd = Xest.Account.Trade.ACL.new(btd)

        assert btd.time == xtd.time
        assert btd.price == xtd.price
        assert btd.qty == xtd.vol
        assert btd.symbol == xtd.pair
      end
    end
  end
end

defmodule XestBinance.Account.TradesHistory.Test do
  use ExUnit.Case
  use ExUnitProperties

  describe "new/1" do
    property "generates a List of Binance.Trade and convert it to a Xest.Account.TradeHistory using the ACL protocol" do
      check all(
              bhist <-
                XestBinance.Account.Trades.Test.binance_trade_generator()
                |> StreamData.list_of()
            ) do
        xhist = Xest.Account.TradesHistory.ACL.new(bhist)

        # checks the history is now a map with trade ids as keys, and xest trades as values
        assert xhist.history ==
                 bhist
                 |> Enum.into(%{}, fn e ->
                   {e.id, Xest.Account.Trade.new(e.symbol, e.price, e.time, e.qty)}
                 end)
      end
    end
  end
end

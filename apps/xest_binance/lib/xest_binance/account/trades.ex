# Since binance.ex already has types for the data returned
# here we use these types and convert from them to the xest representation

# providing implementation for Xest ACL
defimpl Xest.Account.Trade.ACL, for: Binance.Trade do
  def new(%Binance.Trade{
        price: price,
        time: time,
        symbol: symbol,
        qty: qty
      }) do
    Xest.Account.Trade.new(
      symbol,
      price,
      time,
      qty
    )
  end
end

# TODO : find a way to test this during development,
# without querying the actual server... Maybe via already recorded cassettes ? norm / stream_data ?

defimpl Xest.Account.TradesHistory.ACL, for: List do
  def new(trades_list) do
    trades_list
    |> Enum.into(%{}, fn td -> {td.id, Xest.Account.Trade.ACL.new(td)} end)
    |> Xest.Account.TradesHistory.new()
  end
end

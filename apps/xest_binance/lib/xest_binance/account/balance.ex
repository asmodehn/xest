# Since binance.ex already has types for the data returned
# here we use these types and convert from them to the xest representation

# providing implementation for Xest ACL
defimpl Xest.Account.AssetBalance.ACL, for: Map do
  def new(%{"asset" => asset, "free" => free_amount, "locked" => locked_amount}) do
    Xest.Account.AssetBalance.new(
      asset,
      free_amount,
      locked_amount
    )
  end
end

defimpl Xest.Account.Balance.ACL, for: Binance.Account do
  def new(%Binance.Account{balances: balances}) do
    Xest.Account.Balance.new(Enum.map(balances, &Xest.Account.AssetBalance.ACL.new/1))
  end
end

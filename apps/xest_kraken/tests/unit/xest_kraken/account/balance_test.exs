defmodule XestKraken.Account.Balance.Test do
  use ExUnit.Case, async: true

  # TODO norm for property testing of models

  describe "Balance Model" do
    test "has sensible defaults" do
      asset_balance = %XestKraken.Account.Balance{}

      assert asset_balance.balances == []

      assert XestKraken.Account.Balance.new(%{}) == %XestKraken.Account.Balance{
               balances: []
             }
    end
  end

  describe "implementation for Xest ACL" do
    test "works on default value" do
      xest_model =
        %XestKraken.Account.Balance{}
        |> Xest.Account.Balance.ACL.new()

      assert xest_model == %Xest.Account.Balance{balances: []}
    end

    test "works on custom test value" do
      ab =
        %XestKraken.Account.AssetBalance{asset: "BTC", amount: 42.51}
        |> Xest.Account.AssetBalance.ACL.new()

      xest_model =
        %XestKraken.Account.Balance{balances: [ab]}
        |> Xest.Account.Balance.ACL.new()

      assert xest_model ==
               %Xest.Account.Balance{
                 balances: [
                   %Xest.Account.AssetBalance{
                     asset: "BTC",
                     free: 42.51
                   }
                 ]
               }
    end
  end
end

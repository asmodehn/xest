defmodule XestKraken.Account.AssetBalance.Test do
  use ExUnit.Case, async: true

  # TODO norm for property testing of models

  describe "AssetBalance Model" do
    test "has sensible defaults" do
      asset_balance = %XestKraken.Account.AssetBalance{}

      assert asset_balance.amount == 0.0
      assert asset_balance.asset == nil

      assert XestKraken.Account.AssetBalance.new(%{}) == %XestKraken.Account.AssetBalance{}
    end
  end

  describe "implementation for Xest ACL" do
    test "works" do
      xest_model =
        %XestKraken.Account.AssetBalance{asset: "BTC", amount: 42.51}
        |> Xest.Account.AssetBalance.ACL.new()

      assert xest_model == %Xest.Account.AssetBalance{
               asset: "BTC",
               free: 42.51
             }
    end
  end
end

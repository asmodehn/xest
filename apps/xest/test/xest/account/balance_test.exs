defmodule Xest.Account.Balance.Test do
  use ExUnit.Case, async: true

  alias Xest.Account.Balance
  alias Xest.Account.AssetBalance

  test "new asset balance has sensible defaults" do
    assert Balance.new() == %Xest.Account.Balance{
             balances: []
           }

    assert Balance.new([
             %AssetBalance{
               asset: "DOGE",
               free: 1.23,
               locked: 0.0
             }
           ]) ==
             %Balance{
               balances: [
                 %AssetBalance{
                   asset: "DOGE",
                   free: 1.23,
                   locked: 0.0
                 }
               ]
             }
  end
end

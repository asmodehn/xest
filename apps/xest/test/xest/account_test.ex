defmodule Xest.Account.Test do
  use ExUnit.Case, async: true

  alias Xest.Account

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox

  test "new account has sensible defaults" do
    assert Account.new() == %Account{
             balances: [],
             maker_commission: 0,
             taker_commission: 0,
             buyer_commission: 0,
             seller_commission: 0,
             can_trade: false,
             can_withdrawal: false,
             can_deposit: false,
             update_time: ~U[1970-01-01 00:00:00Z],
             account_type: "",
             permissions: []
           }

    DateTimeMock
    |> expect(:utc_now, fn -> ~U[1970-01-01 01:01:01Z] end)

    assert Account.new([Account.AssetBalance.new("DOGE", 1.23, 4.56)]) == %Account{
             balances: [
               %Account.AssetBalance{
                 asset: "DOGE",
                 free: 1.23,
                 locked: 4.56
               }
             ],
             maker_commission: 0,
             taker_commission: 0,
             buyer_commission: 0,
             seller_commission: 0,
             can_trade: false,
             can_withdrawal: false,
             can_deposit: false,
             update_time: ~U[1970-01-01 00:00:00Z],
             account_type: "",
             permissions: []
           }
  end
end

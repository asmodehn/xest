defmodule Xest.Account.TradesHistory.Test do
  use ExUnit.Case, async: true

  alias Xest.Account.Trade
  alias Xest.Account.TradesHistory

  test "new trade history has sensible defaults" do
    assert TradesHistory.new() == %Xest.Account.TradesHistory{
             # Witchcraft quirk...
             history: :%{}
           }

    assert TradesHistory.new(%{
             "DOGEBTC" => %Trade{
               pair: "DOGEBTC",
               price: 12.3,
               time: 42.0,
               vol: 1.0
             }
           }) == %Xest.Account.TradesHistory{
             history: %{
               "DOGEBTC" => %Xest.Account.Trade{
                 pair: "DOGEBTC",
                 price: 12.3,
                 time: 42.0,
                 vol: 1.0
               }
             }
           }
  end
end

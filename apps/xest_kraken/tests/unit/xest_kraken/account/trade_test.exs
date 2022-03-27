defmodule XestKraken.Account.Trade.Test do
  use ExUnit.Case, async: true

  # TODO norm for property testing of models

  describe "Trade Model" do
    test "has sensible defaults" do
      trade = %XestKraken.Account.Trade{}

      assert trade.price == 0.0
      assert trade.vol == 0.0
      assert trade.fee == 0.0
      assert trade.cost == 0.0

      assert XestKraken.Account.Trade.new(%{}) == %XestKraken.Account.Trade{
               cost: 0.0,
               fee: 0.0,
               margin: 0.0,
               misc: "",
               ordertxid: "",
               ordertype: "",
               pair: "",
               postxid: "",
               price: 0.0,
               time: 0.0,
               type: "",
               vol: 0.0
             }
    end
  end

  describe "implementation for Xest ACL" do
    test "works" do
      xest_model =
        %XestKraken.Account.Trade{
          pair: "XXXEUR",
          price: 42.0,
          # TODO: time actual type ?
          time: 123_456_787.2345,
          vol: 51.0
        }
        |> Xest.Account.Trade.ACL.new()

      assert xest_model == %Xest.Account.Trade{
               pair: "XXXEUR",
               price: 42.0,
               # TODO: time actual type ?
               time: 123_456_787.2345,
               vol: 51.0
             }
    end
  end
end

defmodule XestKraken.Account.Trades.Test do
  use ExUnit.Case, async: true

  # TODO norm for property testing of models

  describe "TradesHistory Model" do
    test "has sensible defaults" do
      trades = %XestKraken.Account.Trades{}

      assert trades.trades == %{}

      assert XestKraken.Account.Trades.new(%{}) == %XestKraken.Account.Trades{
               trades: %{}
             }
    end
  end

  describe "implementation for Xest ACL" do
    test "works on default value" do
      xest_model =
        %XestKraken.Account.Trades{}
        |> Xest.Account.TradesHistory.ACL.new()

      assert xest_model == %Xest.Account.TradesHistory{history: %{}}
    end

    test "works on custom test value" do
      td = %XestKraken.Account.Trade{
        pair: "XXXEUR",
        price: 42.0,
        # TODO: time actual type ?
        time: 123_456_787.2345,
        vol: 51.0
      }

      xest_model =
        %XestKraken.Account.Trades{trades: %{"trade_id" => td}}
        |> Xest.Account.TradesHistory.ACL.new()

      assert xest_model ==
               %Xest.Account.TradesHistory{
                 history: %{
                   "trade_id" => %Xest.Account.Trade{
                     pair: "XXXEUR",
                     price: 42.0,
                     # TODO: time actual type ?
                     time: 123_456_787.2345,
                     vol: 51.0
                   }
                 }
               }
    end
  end
end

defmodule Xest.Account.Trade.Test do
  use ExUnit.Case, async: true

  alias Xest.Account.Trade

  test "new trade has sensible defaults" do
    assert Trade.new() == %Trade{
             pair: "",
             price: 0.0,
             time: 0.0,
             vol: 0.0
           }

    assert Trade.new("DOGEBTC") == %Trade{
             pair: "DOGEBTC",
             price: 0.0,
             time: 0.0,
             vol: 0.0
           }
  end
end

defmodule Xest.Account.AssetBalance.Test do
  use ExUnit.Case, async: true

  alias Xest.Account.AssetBalance

  test "new asset balance has sensible defaults" do
    assert AssetBalance.new() == %AssetBalance{
             asset: "",
             free: 0.0,
             locked: 0.0
           }

    assert AssetBalance.new("DOGE") == %AssetBalance{
             asset: "DOGE",
             free: 0.0,
             locked: 0.0
           }
  end
end

defmodule XestBinance.Exchange.Status.Test do
  use ExUnit.Case, async: true

  # TODO norm for property testing of models

  test "converts from binance model" do
    converted =
      %Binance.SystemStatus{status: 1, msg: "maintenance"}
      |> XestBinance.Exchange.Status.new()

    assert converted.status == 1
    assert converted.message == "maintenance"
  end

  describe "implementation for Xest ACL" do
    test "works" do
      xest_model =
        %XestBinance.Exchange.Status{status: 0, message: "online"}
        |> Xest.Exchange.Status.ACL.new()

      assert xest_model == %Xest.Exchange.Status{
               status: :online,
               description: "online"
             }
    end
  end
end

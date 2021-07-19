defmodule XestBinance.Exchange.ServerTime.Test do
  use ExUnit.Case, async: true

  # TODO norm for property testing of models

  @test_time ~U[2021-02-18 08:53:32.313Z]

  test "converts from binance model" do
    converted =
      %{"servertime" => @test_time}
      |> XestBinance.Exchange.ServerTime.new()

    assert converted.servertime == @test_time
  end

  #  TODO : ACL test
  #  describe "implementation for Xest ACL" do
  #    test "works" do
  #      xest_model =
  #        %XestBinance.Exchange.Status{status: 0, message: "online"}
  #        |> Xest.Exchange.Status.ACL.new()
  #
  #      assert xest_model == %Xest.Exchange.Status{
  #               status: :online,
  #               description: "online"
  #             }
  #    end
  #  end
end

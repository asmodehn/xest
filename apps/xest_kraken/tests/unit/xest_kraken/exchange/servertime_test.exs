defmodule XestKraken.Exchange.ServerTime.Test do
  use ExUnit.Case, async: true

  # TODO norm for property testing of models

  @test_time ~U[2021-02-18 08:53:32.313Z]

  test "converts from kraken model" do
    converted =
      %{"unixtime" => @test_time, "rfc1123" => "some data string"}
      |> XestKraken.Exchange.ServerTime.new()

    assert converted.unixtime == @test_time
  end

  describe "implementation for Xest ACL" do
    test "works" do
      xest_model =
        %XestKraken.Exchange.ServerTime{unixtime: @test_time, rfc1123: "some date string"}
        |> Xest.Exchange.ServerTime.ACL.new()

      assert xest_model == %Xest.Exchange.ServerTime{
               servertime: @test_time
             }
    end
  end
end

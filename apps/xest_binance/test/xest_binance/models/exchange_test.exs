defmodule XestBinance.Domain.Exchange.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias XestBinance.Models.Exchange

  test "test exchange model initial values" do
    %Exchange{}
    |> assert_fields(%{
      status: %Binance.SystemStatus{}
    })
  end

  test "test exchange status update" do
    %Exchange{}
    |> Exchange.update(status: %Binance.SystemStatus{msg: "testmsg", status: 42})
    |> assert_fields(%{
      status: %Binance.SystemStatus{msg: "testmsg", status: 42}
    })
  end
end

defmodule Xest.BinanceExchange.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Binance.ApiMock
  import Tesla.Mock

  alias Xest.BinanceExchange

  setup do
    mock(&ApiMock.apimock/1)
    {:ok, exchange} = BinanceExchange.start_link([])
    %{exchange: exchange}
  end

  test "initial value OK", %{exchange: exchange} do
    BinanceExchange.state(exchange)
    |> assert_fields(%{
      status_message: "Unknown",
      status_code: -1,
      server_time_skew: 0
    })
  end

  test "retrieve status OK", %{exchange: exchange} do
    BinanceExchange.status_retrieve(exchange)
    BinanceExchange.state(exchange)
    |> assert_fields(%{
      status_message: "normal",
      status_code: 0
    })
  end

#  test "retrieve servertime OK", %{exchange: exchange} do
#    BinanceExchange.servertime_retrieve(__MODULE__)
#    BinanceExchange.get(__MODULE__)
#    |> assert_fields(%{
#      server_time_skew: 1_613_638_412_313  # TODO : mock local clock ?
#    })
#  end

#  test "time OK" do
#    assert Binance.time() == %{"serverTime" => 1_613_638_412_313}
#  end
end

defmodule Xest.BinanceExchange.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Binance.ApiMock
  import Tesla.Mock

  alias Xest.BinanceExchange

  setup do
    mock(&ApiMock.apimock/1)

    {:ok, exg_pid} = start_supervised(BinanceExchange)
    %{exg_pid: exg_pid}
  end

  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "verifying local clock mock is in place", %{exg_pid: _exg_pid} do
    Xest.LocalUTCClockMock
    |> expect(:utc_now, fn ->
      ~U[2020-01-01 00:00:00.000001Z]
    end)

    assert Xest.BinanceExchange.utc_now() ==
      ~U[2020-01-01 00:00:00.000001Z]
  end

  test "initial value OK", %{exg_pid: exg_pid}  do
    exg_pid
    |> BinanceExchange.state
    |> assert_fields(%{
      status: %{
        message: nil,
        code: nil
      }
    })
    |> assert_fields(%{
      server_time_skew: nil
    })
  end

  test "retrieve status NEEDED", %{exg_pid: exg_pid} do
    exg_pid
    |> BinanceExchange.status
    |> assert_fields(%{
        message: "normal",
        code: 0
    })
  end

  test "retrieve status OPTOUT", %{exg_pid: exg_pid} do
    exg_pid
    |> BinanceExchange.status
    |> assert_fields(%{
        message: "normal",
        code: 0
    })
  end

  test "retrieve status AUTO", %{exg_pid: exg_pid} do
    exg_pid
    |> BinanceExchange.status
    |> assert_fields(%{
        message: "normal",
        code: 0
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

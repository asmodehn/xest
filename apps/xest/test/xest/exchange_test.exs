defmodule Xest.BinanceExchange.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Models
  alias Xest.BinanceExchange
  alias Xest.BinanceClientBehaviourMock

  import Hammox

  setup do
    client_pid =
      start_supervised!({Xest.BinanceClient, name: String.to_atom("#{__MODULE__}.BinanceClient")})

    exg_pid =
      start_supervised!({
        BinanceExchange,
        # passing the created test client to the created test exchange.
        name: String.to_atom("#{__MODULE__}.Exchange"), client: client_pid
      })

    # setting up adapter mock
    BinanceClientBehaviourMock
    |> allow(self(), client_pid)

    #    |> allow(self(), exg_pid)

    %{client_pid: client_pid, exg_pid: exg_pid}
  end

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "initial value OK", %{client_pid: client_pid, exg_pid: exg_pid} do
    exg_pid
    |> BinanceExchange.state()
    |> assert_fields(%{
      model: %Models.Exchange{
        status: %Models.ExchangeStatus{
          message: nil,
          code: nil
        },
        server_time_skew_usec: nil
      }
    })
  end

  test "retrieve status", %{exg_pid: exg_pid} do
    BinanceClientBehaviourMock
    |> expect(:system_status, fn -> {:ok, %{"msg" => "normal", "status" => 0}} end)

    #     assert Xest.BinanceClient.system_status(client_pid) == {:ok, %{"msg" => "normal", "status" => 0}}

    exg_pid
    |> BinanceExchange.status()
    |> assert_fields(%{
      message: "normal",
      code: 0
    })
  end

  # TODO
  #    test "retrieve servertime OK", %{exchange: exchange} do
  #    BinanceClientBehaviourMock
  #    |> expect(:time, fn -> %{"serverTime" => 1_613_638_412_313} end)
  #    |> allow(self(), exg_pid)
  #      BinanceExchange.servertime_retrieve(__MODULE__)
  #      BinanceExchange.get(__MODULE__)
  #      |> assert_fields(%{
  #        server_time_skew: 1_613_638_412_313  # TODO : mock local clock ?
  #      })
  #    end

  #  test "time OK" do
  #    assert Binance.time() == %{"serverTime" => 1_613_638_412_313}
  #  end
end

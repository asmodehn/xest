defmodule Xest.BinanceExchange.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Models
  alias Xest.BinanceExchange
  alias Xest.BinanceClientBehaviourMock

  import Hammox

  @time_stop ~U[2021-02-18 08:53:32.313Z]

  setup do
    client_id = {:via, Registry, Xest.BinanceClient.via_tuple("test_client")}

    # starting client process, relying on registry to access it...
    start_supervised!({Xest.BinanceClient, name: client_id})

    exg_pid =
      start_supervised!({
        BinanceExchange,
        # passing the created test client to the created test exchange.
        name: String.to_atom("#{__MODULE__}.Exchange"),
        client: client_id,
        clock:
          Xest.ShadowClock.new(
            fn -> BinanceExchange.remote_clock(client_id) end,
            fn -> @time_stop end
          )
      })

    # setting up adapter mock
    BinanceClientBehaviourMock
    |> allow(self(), client_id)

    %{client_id: client_id, exg_pid: exg_pid}
  end

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "initial value OK", %{client_id: client_id, exg_pid: exg_pid} do
    exg_pid
    |> BinanceExchange.state()
    |> assert_fields(%{
      model: %Models.Exchange{
        status: %Models.ExchangeStatus{
          message: nil,
          code: nil
        }
      },
      client: client_id
      #      shadow_clock: %Xest.ShadowClock{}
    })
  end

  test "retrieve status", %{exg_pid: exg_pid} do
    BinanceClientBehaviourMock
    |> expect(:system_status, fn -> {:ok, %{"msg" => "normal", "status" => 0}} end)

    exg_pid
    |> BinanceExchange.status()
    |> assert_fields(%{
      message: "normal",
      code: 0
    })
  end

  test "retrieve servertime OK", %{exg_pid: exg_pid} do
    BinanceClientBehaviourMock
    |> expect(:time, fn ->
      {:ok, %{"serverTime" => @time_stop |> DateTime.to_unix(:millisecond)}}
    end)

    assert BinanceExchange.servertime(exg_pid) == @time_stop
  end
end

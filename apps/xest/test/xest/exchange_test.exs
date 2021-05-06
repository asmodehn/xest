defmodule Xest.BinanceExchange.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Models
  alias Xest.BinanceExchange
  alias Xest.BinanceServerBehaviourMock

  import Hammox

  @time_stop ~U[2021-02-18 08:53:32.313Z]

  setup do
    # starting server mock process...
    # start_supervised!({BinanceServerBehaviourMock, name: String.to_atom("#{__MODULE__}.ServerProcess")})
    server_pid = nil

    exg_pid =
      start_supervised!({
        BinanceExchange,
        # passing nil as we rely on a mock here.
        name: String.to_atom("#{__MODULE__}.Process"),
        client: server_pid,
        clock:
          Xest.ShadowClock.new(
            fn -> BinanceServerBehaviourMock.time!(server_pid) end,
            fn -> @time_stop end
          )
      })

    # setting up server mock to tes the chain
    # Exchange -> Agent messaging -> BinanceServer
    # without relying on a specific server implementation
    BinanceServerBehaviourMock
    |> allow(self(), exg_pid)

    %{server_pid: server_pid, exg_pid: exg_pid}
  end

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "initial value OK", %{server_pid: server_pid, exg_pid: exg_pid} do
    exg_pid
    |> BinanceExchange.state()
    |> assert_fields(%{
      model: %Models.Exchange{
        status: %Models.ExchangeStatus{
          message: nil,
          code: nil
        }
      },
      client: server_pid
      #      shadow_clock: %Xest.ShadowClock{}
    })
  end

  test "retrieve status", %{exg_pid: exg_pid} do
    BinanceServerBehaviourMock
    |> expect(:system_status, fn _ ->
      {:ok, %Models.ExchangeStatus{message: "normal", code: 0}}
    end)

    exg_pid
    |> BinanceExchange.status()
    |> assert_fields(%{
      message: "normal",
      code: 0
    })
  end

  test "retrieve servertime OK", %{exg_pid: exg_pid} do
    BinanceServerBehaviourMock
    |> expect(:time!, fn _ -> @time_stop end)

    assert BinanceExchange.servertime(exg_pid) == @time_stop
  end
end

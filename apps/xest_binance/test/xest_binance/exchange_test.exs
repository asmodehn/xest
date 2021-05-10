defmodule XestBinance.Exchange.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias XestBinance.Models
  alias XestBinance.Exchange
  alias XestBinance.ServerBehaviourMock

  import Hammox

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: XestBinance.Exchange, behaviour: XestBinance.Ports.ExchangeBehaviour

  @time_stop ~U[2021-02-18 08:53:32.313Z]

  setup do
    # starting server mock process...
    # start_supervised!({BinanceServerBehaviourMock, name: String.to_atom("#{__MODULE__}.ServerProcess")})
    server_pid = nil

    exg_pid =
      start_supervised!({
        Exchange,
        # passing nil as we rely on a mock here.
        name: String.to_atom("#{__MODULE__}.Process"),
        client: server_pid,
        clock:
          Xest.ShadowClock.new(
            fn -> ServerBehaviourMock.time!(server_pid) end,
            fn -> @time_stop end
          )
      })

    # setting up server mock to tes the chain
    # Exchange -> Agent messaging -> BinanceServer
    # without relying on a specific server implementation
    ServerBehaviourMock
    |> allow(self(), exg_pid)

    %{server_pid: server_pid, exg_pid: exg_pid}
  end

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "initial value OK", %{server_pid: server_pid, exg_pid: exg_pid} do
    exg_pid
    |> Exchange.state()
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
    ServerBehaviourMock
    |> expect(:system_status, fn _ ->
      {:ok, %Models.ExchangeStatus{message: "normal", code: 0}}
    end)

    exg_pid
    |> Exchange.status()
    |> assert_fields(%{
      message: "normal",
      code: 0
    })
  end

  test "after retrieving status, state is still usable", %{exg_pid: exg_pid} do
    ServerBehaviourMock
    |> expect(:system_status, fn _ ->
      {:ok, %Models.ExchangeStatus{message: "normal", code: 0}}
    end)

    Exchange.status(exg_pid)

    exg_pid
    |> Exchange.status()
    |> assert_fields(%{
      message: "normal",
      code: 0
    })
  end

  test "retrieve servertime OK", %{exg_pid: exg_pid} do
    ServerBehaviourMock
    |> expect(:time!, fn _ -> @time_stop end)

    assert Exchange.servertime(exg_pid) == @time_stop
  end

  test "after retrieving servertime, state is still usable", %{exg_pid: exg_pid} do
    ServerBehaviourMock
    |> expect(:time!, fn _ -> @time_stop end)

    Exchange.servertime(exg_pid)
    assert Exchange.servertime(exg_pid) == @time_stop
  end
end

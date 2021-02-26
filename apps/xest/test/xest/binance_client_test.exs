defmodule Xest.BinanceClient.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.BinanceClient
  alias Xest.BinanceClientBehaviourMock

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox

  setup :verify_on_exit!

  setup do
    client_pid = start_supervised!({Xest.BinanceClient, name: __MODULE__})
#    BinanceClientBehaviourMock
#    |> expect(:system_status, fn -> %{"msg" => "normal", "status" => 0} end)
#    |> expect(:time, fn -> %{"serverTime" => 1_613_638_412_313} end)
#    |> allow(self(), client_pid)

    %{client_pid: client_pid}
  end

  test "system status OK", %{client_pid: client_pid} do
    BinanceClientBehaviourMock
    |> expect(:system_status, fn -> {:ok ,%{"msg" => "normal", "status" => 0}} end)
    |> allow(self(), client_pid)

    assert BinanceClient.system_status(client_pid) == {:ok, %{"msg" => "normal", "status" => 0}}
  end

  #  test "ping OK", %{pid: _pid} do
  #    assert BinanceClient.ping() == {:ok, %{}}
  #  end

  test "time OK", %{client_pid: client_pid} do
    BinanceClientBehaviourMock
    |> expect(:time, fn -> {:ok , %{"serverTime" => 1_613_638_412_313}} end)
    |> allow(self(), client_pid)

    assert BinanceClient.time(client_pid) == {:ok, %{"serverTime" => 1_613_638_412_313}}
  end
end

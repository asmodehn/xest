defmodule XestBinance.Server.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias XestBinance.ClientBehaviourMock

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: XestBinance.Server, behaviour: XestBinance.Ports.ServerBehaviour

  setup :verify_on_exit!

  #  test """
  #  When using via_tuple() to start the process
  #  Then process can be looked up via the registry
  #  """ do
  #    client_pid =
  #      start_supervised!(
  #        {Xest.BinanceClient, name: Xest.BinanceClient}}
  #      )
  #
  #    [{pid, val}] = apply(Registry, :lookup, Xest.BinanceClient.via_tuple() |> Tuple.to_list())
  #
  #    assert pid == client_pid
  #    assert val == nil
  #  end
  #
  #  test """
  #  When using via_tuple(key, value) to start the process
  #  Then process and value can be looked up via the registry
  #  """ do
  #    client_pid =
  #      start_supervised!(
  #        {Xest.BinanceClient, name: {:via, Registry, Xest.BinanceClient.via_tuple("mykey", 42)}}
  #      )
  #
  #    [{pid, val}] =
  #      apply(Registry, :lookup, Xest.BinanceClient.via_tuple("mykey") |> Tuple.to_list())
  #
  #    assert pid == client_pid
  #    assert val == 42
  #  end
  #
  #  test """
  #  When starting with no name
  #  Then process registers itself to the registry
  #  """ do
  #    client_pid = start_supervised!(Xest.BinanceClient)
  #
  #    [{pid, val}] = apply(Registry, :lookup, Xest.BinanceClient.via_tuple() |> Tuple.to_list())
  #
  #    assert pid == client_pid
  #    assert val == :self_registered
  #  end
  #
  #  test """
  #  When starting with usual name
  #  Then does NOT register itself to the registry
  #  """ do
  #    start_supervised!({Xest.BinanceClient, name: :binance_client})
  #
  #    assert [] ==
  #             apply(Registry, :lookup, Xest.BinanceClient.via_tuple() |> Tuple.to_list())
  #  end

  describe "By default" do
    setup do
      # starts server test process
      server_pid =
        start_supervised!({
          XestBinance.Server,
          name: XestBinance.Server.Test.Process
        })

      # setting up adapter mock to test the chain :
      # BinanceServer -> GenServer messaging -> BinanceClient / API
      # without relying on specific client implementation (tesla or another)
      ClientBehaviourMock
      |> allow(self(), server_pid)

      %{server_pid: server_pid}
    end

    test "provides system status", %{server_pid: server_pid} do
      ClientBehaviourMock
      |> expect(:system_status, fn -> {:ok, %{"msg" => "normal", "status" => 0}} end)

      assert system_status(server_pid) ==
               {:ok, %XestBinance.Models.ExchangeStatus{message: "normal", code: 0}}
    end

    test "provides time", %{server_pid: server_pid} do
      udt = ~U[2021-02-18 08:53:32.313Z]

      ClientBehaviourMock
      |> expect(:time, fn -> {:ok, %{"serverTime" => DateTime.to_unix(udt, :millisecond)}} end)

      assert time(server_pid) == {:ok, udt}
    end

    # TODO: test to document default ping behavior
  end

  describe "With custom ping period" do
    setup do
      server_pid =
        start_supervised!(
          {XestBinance.Server, name: __MODULE__, next_ping_wait_time: :timer.seconds(1)}
        )

      %{server_pid: server_pid}
    end

    test "provides read access to the next ping period", %{server_pid: server_pid} do
      %{
        next_ping_ref: _ping_timer,
        next_ping_wait_time: period
      } = XestBinance.Server.next_ping_schedule(server_pid)

      # TODO : is there a way to make this public (part of behaviour) somehow ?

      assert period == 1000
    end

    test "provides write access to the next ping period", %{server_pid: server_pid} do
      %{
        next_ping_ref: _ping_timer,
        next_ping_wait_time: period
      } = XestBinance.Server.next_ping_schedule(server_pid, :timer.seconds(0.5))

      assert period == 500
    end

    # tag for time related tests (should run with side-effect tests)
    @tag :timed
    test " ping happens in due time ", %{server_pid: server_pid} do
      # we need the current pid of this process
      test_pid = self()

      ClientBehaviourMock
      |> expect(:ping, fn ->
        send(test_pid, :ping_done)
        {:ok, %{}}
      end)
      |> allow(test_pid, server_pid)

      assert_receive :ping_done, :timer.seconds(1) * 2
    end

    # TODO : test ping reschedule when other request happens...
  end
end

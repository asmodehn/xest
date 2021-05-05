defmodule Xest.BinanceClient.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.BinanceClient
  alias Xest.BinanceClientBehaviourMock

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox

  setup :verify_on_exit!

  test """
  When using via_tuple() to start the process
  Then process can be looked up via the registry
  """ do
    client_pid =
      start_supervised!(
        {Xest.BinanceClient, name: {:via, Registry, Xest.BinanceClient.via_tuple()}}
      )

    [{pid, val}] = apply(Registry, :lookup, Xest.BinanceClient.via_tuple() |> Tuple.to_list())

    assert pid == client_pid
    assert val == nil
  end

  test """
  When using via_tuple(key, value) to start the process
  Then process and value can be looked up via the registry
  """ do
    client_pid =
      start_supervised!(
        {Xest.BinanceClient, name: {:via, Registry, Xest.BinanceClient.via_tuple("mykey", 42)}}
      )

    [{pid, val}] =
      apply(Registry, :lookup, Xest.BinanceClient.via_tuple("mykey") |> Tuple.to_list())

    assert pid == client_pid
    assert val == 42
  end

  test """
  When starting with no name
  Then process registers itself to the registry
  """ do
    client_pid = start_supervised!(Xest.BinanceClient)

    [{pid, val}] = apply(Registry, :lookup, Xest.BinanceClient.via_tuple() |> Tuple.to_list())

    assert pid == client_pid
    assert val == :self_registered
  end

  test """
  When starting with usual name
  Then does NOT register itself to the registry
  """ do
    start_supervised!({Xest.BinanceClient, name: :binance_client})

    assert [] ==
             apply(Registry, :lookup, Xest.BinanceClient.via_tuple() |> Tuple.to_list())
  end

  describe "By default" do
    setup do
      # starts client process
      # ,
      client_pid =
        start_supervised!({
          Xest.BinanceClient,
          name: {:via, Registry, Xest.BinanceClient.via_tuple()}
        })

      # setting up adapter mock
      BinanceClientBehaviourMock
      |> allow(self(), client_pid)

      %{client_pid: client_pid}
    end

    test "provides system status", %{client_pid: client_pid} do
      BinanceClientBehaviourMock
      |> expect(:system_status, fn -> {:ok, %{"msg" => "normal", "status" => 0}} end)

      assert BinanceClient.system_status(client_pid) == {:ok, %{"msg" => "normal", "status" => 0}}
    end

    test "provides time", %{client_pid: client_pid} do
      BinanceClientBehaviourMock
      |> expect(:time, fn -> {:ok, %{"serverTime" => 1_613_638_412_313}} end)

      assert BinanceClient.time(client_pid) == {:ok, %{"serverTime" => 1_613_638_412_313}}
    end

    # TODO: test to document default ping behavior
  end

  describe "With custom ping period" do
    setup do
      client_pid =
        start_supervised!(
          {Xest.BinanceClient, name: __MODULE__, next_ping_wait_time: :timer.seconds(1)}
        )

      %{client_pid: client_pid}
    end

    test "provides read access to the next ping period", %{client_pid: client_pid} do
      %{
        next_ping_ref: _ping_timer,
        next_ping_wait_time: period
      } = BinanceClient.next_ping_schedule(client_pid)

      assert period == 1000
    end

    test "provides write access to the next ping period", %{client_pid: client_pid} do
      %{
        next_ping_ref: _ping_timer,
        next_ping_wait_time: period
      } = BinanceClient.next_ping_schedule(client_pid, :timer.seconds(0.5))

      assert period == 500
    end

    # tag for time related tests (should run with side-effect tests)
    @tag :timed
    test " ping happens in due time ", %{client_pid: client_pid} do
      # we need the current pid of this process
      test_pid = self()

      BinanceClientBehaviourMock
      |> expect(:ping, fn ->
        send(test_pid, :ping_done)
        {:ok, %{}}
      end)
      |> allow(test_pid, client_pid)

      assert_receive :ping_done, :timer.seconds(1) * 2
    end

    # TODO : test ping reschedule when other request happens...
  end
end

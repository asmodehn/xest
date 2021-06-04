defmodule XestBinance.Exchange.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias XestBinance.Exchange
  alias XestBinance.Adapter

  import Hammox

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: XestBinance.Exchange, behaviour: XestBinance.Exchange.Behaviour

  @time_stop ~U[2021-02-18 08:53:32.313Z]

  setup do
    exg_pid =
      start_supervised!({
        Exchange,
        # passing nil as we rely on a mock here.
        name: String.to_atom("#{__MODULE__}.Process"),
        client: nil,
        clock:
          Xest.ShadowClock.new(
            fn -> Adapter.servertime().servertime end,
            fn -> @time_stop end
          )
      })

    #    before each test
    # cleanup the cache and ignore result
    _nb_erased = Adapter.Cache.delete_all()

    # setting up adapter mock to test the chain
    # Exchange interface -> messaging in agent -> Adapter
    # without relying on a specific adapter implementation
    Adapter.Mock
    |> allow(self(), exg_pid)

    %{exg_pid: exg_pid}
  end

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "initial value OK", %{exg_pid: exg_pid} do
    exg_pid
    |> Exchange.state()
    |> assert_fields(%{
      status: nil,
      client: nil,
      servertime: nil
      #      shadow_clock: %Xest.ShadowClock{}
    })
  end

  test "retrieve status", %{exg_pid: _exg_pid} do
    Adapter.Mock
    |> expect(:system_status, fn _ ->
      {:ok, %Binance.SystemStatus{msg: "normal", status: 0}}
    end)

    Exchange.status()
    |> assert_fields(%{
      message: "normal",
      status: 0
    })
  end

  test "after retrieving status, state is still usable", %{exg_pid: _exg_pid} do
    Adapter.Mock
    |> expect(:system_status, fn _ ->
      {:ok, %Binance.SystemStatus{msg: "normal", status: 0}}
    end)

    Exchange.status()

    Exchange.status()
    |> assert_fields(%{
      message: "normal",
      status: 0
    })
  end

  test "retrieve servertime OK", %{exg_pid: _exg_pid} do
    Adapter.Mock
    |> expect(:servertime, fn _ -> {:ok, @time_stop} end)

    servertime = Exchange.servertime()
    assert servertime == %XestBinance.Exchange.ServerTime{servertime: @time_stop}
  end

  test "after retrieving servertime, state is still usable", %{exg_pid: _exg_pid} do
    Adapter.Mock
    # Not needed more than once because of the cache
    |> expect(:servertime, fn _ -> {:ok, @time_stop} end)

    Exchange.servertime()

    servertime = Exchange.servertime()
    assert servertime == %XestBinance.Exchange.ServerTime{servertime: @time_stop}
  end
end

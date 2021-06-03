defmodule XestKraken.Exchange.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  #  alias Xest.ShadowClock

  alias XestKraken.Exchange
  alias XestKraken.Adapter

  import Hammox

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: XestKraken.Exchange, behaviour: XestKraken.Exchange.Behaviour

  @time_stop ~U[2021-02-18 08:53:32.313Z]

  setup do
    exg_pid =
      start_supervised!({
        Exchange,
        # passing nil as we rely on a mock here.
        name: String.to_atom("#{__MODULE__}.Process")
        #        clock:
        #          Xest.ShadowClock.new(
        #            fn -> ServerBehaviourMock.time!(server_pid) end,
        #            fn -> @time_stop end
        #          )
      })

    # setting up adapter mock to test the chain
    # Exchange -> Agent messaging -> KrakenAdapter
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
      status: nil
      #      shadow_clock: %Xest.ShadowClock{}
    })
  end

  test "retrieve status", %{exg_pid: exg_pid} do
    Adapter.Mock
    |> expect(:system_status, fn _ ->
      {:ok, %{status: "normal", timestamp: @time_stop}}
    end)

    exg_pid
    |> Exchange.status()
    |> assert_fields(%{
      status: "normal",
      timestamp: @time_stop
    })
  end

  test "after retrieving status, state is still usable", %{exg_pid: exg_pid} do
    Adapter.Mock
    |> expect(:system_status, fn _ ->
      {:ok, %{status: "maintenance", timestamp: @time_stop}}
    end)

    Exchange.status(exg_pid)

    exg_pid
    |> Exchange.status()
    |> assert_fields(%{
      status: "maintenance",
      timestamp: @time_stop
    })
  end

  test "retrieve servertime OK", %{exg_pid: exg_pid} do
    Adapter.Mock
    |> expect(:servertime, fn _ -> {:ok, %{unixtime: @time_stop, rfc1123: "some date string"}} end)

    servertime = Exchange.servertime(exg_pid)

    assert servertime == %XestKraken.Exchange.ServerTime{
             unixtime: @time_stop,
             rfc1123: "some date string"
           }
  end

  test "after retrieving servertime, state is still usable", %{exg_pid: exg_pid} do
    Adapter.Mock
    |> expect(:servertime, fn _ -> {:ok, %{unixtime: @time_stop, rfc1123: "some date string"}} end)
    |> expect(:servertime, fn _ -> {:ok, %{unixtime: @time_stop, rfc1123: "some date string"}} end)

    Exchange.servertime(exg_pid)

    servertime = Exchange.servertime(exg_pid)

    assert servertime == %XestKraken.Exchange.ServerTime{
             unixtime: @time_stop,
             rfc1123: "some date string"
           }
  end
end

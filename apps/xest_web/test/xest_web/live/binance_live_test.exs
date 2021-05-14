defmodule XestWeb.BinanceLiveTest do
  use XestWeb.ConnCase

  import Phoenix.LiveViewTest

  alias XestBinance.Models.ExchangeStatus
  alias XestBinance.ExchangeBehaviourMock

  import Hammox

  @time_stop ~U[2021-02-18 08:53:32.313Z]

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  setup do
    # Setting up shadow clock to be used in mock
    clock =
      Xest.ShadowClock.new(
        fn -> @time_stop end,
        fn -> @time_stop end
      )

    %{clock: clock}
  end

  test "disconnected and connected render", %{conn: conn, clock: clock} do
    ExchangeBehaviourMock
    |> expect(:servertime, fn _ -> clock end)
    |> expect(:status, fn _ -> %ExchangeStatus{message: "test"} end)

    conn = get(conn, "/binance")
    assert html_response(conn, 200) =~ "Status: N/A"
    assert html_response(conn, 200) =~ "00:00:00"

    {:ok, _view, html} = live(conn, "/binance")

    # after websocket connection, message changed
    assert html =~ "Status: test"
    assert html =~ "08:53:32"
    # TODO : more
  end

  test "sending a message to the liveview process displays it in flash view", %{
    conn: conn,
    clock: clock
  } do
    ExchangeBehaviourMock
    |> expect(:servertime, fn _ -> clock end)
    |> expect(:status, fn _ -> %ExchangeStatus{message: "test"} end)

    {:ok, view, _html} = live(conn, "/binance")

    send(view.pid, "Test Info Message")
    assert render(view) =~ "Test Info Message"
  end
end

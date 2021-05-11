defmodule XestWeb.BinanceLiveTest do
  use XestWeb.ConnCase

  import Phoenix.LiveViewTest

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

    #    |> expect(:status, fn _ -> %ExchangeStatus{} end)

    conn = get(conn, "/binance")
    assert html_response(conn, 200) =~ "Status: N/A"
    assert html_response(conn, 200) =~ "00:00:00"

    {:ok, _view, html} = live(conn, "/binance")

    # after websocket connection, message changed
    assert html =~ "Status: requesting..."
    assert html =~ "08:53:32"
    # TODO : more
  end
end

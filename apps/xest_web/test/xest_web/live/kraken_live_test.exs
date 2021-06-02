defmodule XestWeb.KrakenLiveTest do
  use XestWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Xest.Exchange.Mock

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

  test "disconnected and connected render", %{conn: conn, clock: _clock} do
    Mock
    |> expect(:status, fn :kraken -> %Xest.Exchange.Status{description: "test"} end)

    conn = get(conn, "/kraken")

    html = html_response(conn, 200)
    assert html =~ "Status: N/A"

    {:ok, _view, html} = live(conn, "/kraken")

    # after websocket connection, message changed
    assert html =~ "Status: test"
  end

  test "sending a message to the liveview process displays it in flash view", %{
    conn: conn,
    clock: _clock
  } do
    Mock
    |> expect(:status, fn :kraken -> %Xest.Exchange.Status{description: "test"} end)

    {:ok, view, _html} = live(conn, "/kraken")

    send(view.pid, "Test Info Message")
    assert render(view) =~ "Test Info Message"
  end
end

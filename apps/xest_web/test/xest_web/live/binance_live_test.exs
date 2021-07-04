defmodule XestWeb.BinanceLiveTest do
  use XestWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Xest.Exchange
  alias Xest.Clock
  alias Xest.Account

  import Hammox

  @time_stop ~U[2021-02-18 08:53:32.313Z]

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "disconnected and connected render", %{conn: conn} do
    Exchange.Mock
    |> expect(:status, fn :binance -> %Exchange.Status{status: :online, description: "test"} end)

    Clock.Mock
    |> expect(:utc_now, fn :binance -> @time_stop end)

    Account.Mock
    |> expect(:balance, fn :binance ->
      %Account.Balance{
        balances: [%Account.AssetBalance{asset: "BTC", free: "1.23", locked: "4.56"}]
      }
    end)

    conn = get(conn, "/binance")

    html = html_response(conn, 200)
    assert html =~ "Status: N/A"
    assert html =~ "00:00:00"
    refute html =~ "BTC"

    {:ok, _view, html} = live(conn, "/binance")

    # after websocket connection, message changed
    assert html =~ "Status: test"
    assert html =~ "08:53:32"
    assert html =~ "BTC\n1.23\n(Locked: 4.56)"
  end

  test "sending a message to the liveview process displays it in flash view", %{
    conn: conn
  } do
    Exchange.Mock
    |> expect(:status, fn :binance -> %Exchange.Status{status: :online, description: "test"} end)

    Clock.Mock
    |> expect(:utc_now, fn :binance -> @time_stop end)

    Account.Mock
    |> expect(:balance, fn :binance ->
      %Account.Balance{
        balances: [%Account.AssetBalance{asset: "BTC", free: "1.23", locked: "4.56"}]
      }
    end)

    {:ok, view, _html} = live(conn, "/binance")

    send(view.pid, "Test Info Message")
    assert render(view) =~ "Test Info Message"
  end
end

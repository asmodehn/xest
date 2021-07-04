defmodule XestWeb.KrakenLiveTest do
  use XestWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Xest.Exchange
  alias Xest.Clock
  alias Xest.Account

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "disconnected and connected render", %{conn: conn} do
    Clock.Mock
    |> expect(:utc_now, fn :kraken -> ~U[2020-02-02 02:02:02.020Z] end)

    Exchange.Mock
    |> expect(:status, fn :kraken -> %Exchange.Status{description: "test"} end)

    Account.Mock
    |> expect(:balance, fn :kraken ->
      %Xest.Account.Balance{
        balances: [
          %Xest.Account.AssetBalance{
            asset: "ZEUR",
            free: "100.0000"
          },
          %Account.AssetBalance{
            asset: "XETH",
            free: "0.1000000000"
          },
          %Account.AssetBalance{
            asset: "XXBT",
            free: "0.0100000000"
          }
        ]
      }
    end)

    # TODO : Account to Mock it (keeping auth design internal to the connector)

    conn = get(conn, "/kraken")

    html = html_response(conn, 200)
    assert html =~ "Status: N/A"
    assert html =~ "00:00:00"

    {:ok, _view, html} = live(conn, "/kraken")

    # after websocket connection, message changed
    assert html =~ "Status: test"
    assert html =~ "02:02:02"

    # TODO : test balance
  end

  test "sending a message to the liveview process displays it in flash view", %{
    conn: conn
  } do
    Clock.Mock
    |> expect(:utc_now, fn :kraken -> ~U[2020-02-02 02:02:02.020Z] end)

    Exchange.Mock
    |> expect(:status, fn :kraken -> %Exchange.Status{description: "test"} end)

    Account.Mock
    |> expect(:balance, fn :kraken ->
      %Xest.Account.Balance{
        balances: [
          %Xest.Account.AssetBalance{
            asset: "ZEUR",
            free: "100.0000"
          },
          %Account.AssetBalance{
            asset: "XETH",
            free: "0.1000000000"
          },
          %Account.AssetBalance{
            asset: "XXBT",
            free: "0.0100000000"
          }
        ]
      }
    end)

    {:ok, view, _html} = live(conn, "/kraken")

    send(view.pid, "Test Info Message")
    assert render(view) =~ "Test Info Message"
  end
end

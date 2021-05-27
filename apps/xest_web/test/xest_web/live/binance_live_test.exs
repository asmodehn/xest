defmodule XestWeb.BinanceLiveTest do
  use XestWeb.ConnCase

  import Phoenix.LiveViewTest

  alias XestBinance.ExchangeBehaviourMock
  alias XestBinance.AccountBehaviourMock

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
    |> expect(:status, fn _ -> %Xest.ExchangeStatus{message: "test"} end)

    AccountBehaviourMock
    |> expect(:account, fn _ ->
      %Binance.Account{
        balances: [%{"asset" => "BTC", "free" => "1.23", "locked" => "4.56"}]
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
    conn: conn,
    clock: clock
  } do
    ExchangeBehaviourMock
    |> expect(:servertime, fn _ -> clock end)
    |> expect(:status, fn _ -> %Xest.ExchangeStatus{message: "test"} end)

    AccountBehaviourMock
    |> expect(:account, fn _ ->
      %Binance.Account{
        balances: [%{"asset" => "BTC", "free" => "1.23", "locked" => "4.56"}]
      }
    end)

    {:ok, view, _html} = live(conn, "/binance")

    send(view.pid, "Test Info Message")
    assert render(view) =~ "Test Info Message"
  end
end

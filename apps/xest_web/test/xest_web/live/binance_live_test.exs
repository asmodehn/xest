defmodule XestWeb.BinanceLiveTest do
  use XestWeb.ConnCase

  import Phoenix.LiveViewTest

  alias XestBinance.ExchangeBehaviourMock

  import Hammox

  @time_stop ~U[2021-02-18 08:53:32.313Z]

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "disconnected and connected render", %{conn: conn} do
    ExchangeBehaviourMock
    # TODO : fix this, only one call
    |> expect(:servertime, fn _ -> @time_stop end)
    |> expect(:servertime, fn _ -> @time_stop end)

    #    |> expect(:status, fn _ -> %ExchangeStatus{} end)

    {:ok, page_live, disconnected_html} = live(conn, "/binance")
    assert disconnected_html =~ "Status: N/A"
    # will switch to normal only after user click button
    assert render(page_live) =~ "Status: N/A"
  end
end

defmodule XestWeb.BinanceLiveTest do
  use XestWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Xest.Binance.ApiMock
  import Tesla.Mock

  setup_all do  # TODO : inestigate why we need global here ? local doesnt work ?
    mock_global(&ApiMock.apimock/1)
    :ok
  end


  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/binance")
    assert disconnected_html =~ "Status: N/A"
    assert render(page_live) =~ "Status: N/A"  # will switch to normal only after user click button
  end

  # as a static page
#  test "GET /binance", %{conn: conn} do
#    conn = get(conn, "/binance")
#    assert html_response(conn, 200) =~ "Hello Binance"
#    assert html_response(conn, 200) =~ "Status: normal"
#  end
end

defmodule XestWeb.BinanceLiveTest do
  use XestWeb.ConnCase

  import Phoenix.LiveViewTest

  alias XestBinance.RestApiMock
  import Tesla.Mock

  # TODO : inestigate why we need global here ? local doesnt work ?
  setup_all do
    mock_global(&RestApiMock.apimock/1)
    :ok
  end

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/binance")
    assert disconnected_html =~ "Status: N/A"
    # will switch to normal only after user click button
    assert render(page_live) =~ "Status: N/A"
  end

  # TODO : server time !
  # as a static page
  #  test "GET /binance", %{conn: conn} do
  #    conn = get(conn, "/binance")
  #    assert html_response(conn, 200) =~ "Hello Binance"
  #    assert html_response(conn, 200) =~ "Status: normal"
  #  end
end

defmodule XestWeb.BinanceControllerTest do
  use XestWeb.ConnCase

  alias Xest.Binance.ApiMock
  import Tesla.Mock

  setup do
    mock(&ApiMock.apimock/1)
    :ok
  end

  test "GET /binance", %{conn: conn} do
    conn = get(conn, "/binance")
    assert html_response(conn, 200) =~ "Hello Binance"
    assert html_response(conn, 200) =~ "Status: normal"
  end
end

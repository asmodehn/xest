defmodule XestWeb.PageControllerTest do
  use XestWeb.ConnCase

  test "GET /hello", %{conn: conn} do
    conn = get(conn, "/hello")
    assert html_response(conn, 200) =~ "Hello User"
  end
end

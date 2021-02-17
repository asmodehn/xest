defmodule XestWeb.PageController do
  use XestWeb, :controller

  def index(conn, _params) do
    render(conn, "hello.html")
  end
end

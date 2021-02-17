defmodule XestWeb.BinanceController do
  use XestWeb, :controller

  alias Xest.Binance

  require Logger

  def index(conn, _params) do
    status = Binance.system_status()

    Logger.info("status: #{inspect(status)}")

    render(conn, "binance.html", %{
      status: status
    })
  end
end

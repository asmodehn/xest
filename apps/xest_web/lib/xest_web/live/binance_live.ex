defmodule XestWeb.BinanceLive do
  use XestWeb, :live_view

  require Logger

  alias Xest.Binance

  @impl true
  def mount(_params, session, socket) do
    # connection or refresh
    Logger.debug("mount with token: " <> session["_csrf_token"])
    {:ok, assign(socket, status_msg: "N/A")}
  end

  @impl true
  def handle_event("get_status", _value, socket) do
    Logger.debug("clicked !")

    status = Binance.system_status()

    Logger.info("status: #{inspect(status)}")

    {:noreply, assign(socket, status_msg: status["msg"])}
  end
end

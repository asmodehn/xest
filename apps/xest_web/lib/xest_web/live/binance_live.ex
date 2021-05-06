defmodule XestWeb.BinanceLive do
  use XestWeb, :live_view

  require Logger

  alias Xest.BinanceExchange

  @impl true
  def mount(_params, session, socket) do
    # connection or refresh
    Logger.debug("mount with token: " <> session["_csrf_token"])

    # setup a self tick with a second period
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    socket =
      socket
      |> put_date()
      |> assign(status_msg: "N/A")

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  @impl true
  def handle_event("nav", _path, socket) do
    IO.inspect(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_event("get_status", _value, socket) do
    Logger.debug("clicked !")

    status =
      BinanceExchange.status(
        # finding the process via its module name...
        Process.whereis(BinanceExchange)
      )

    Logger.info("status: #{inspect(status)}")

    {:noreply, assign(socket, status_msg: status.message)}
  end

  defp put_date(socket) do
    time =
      BinanceExchange.servertime(
        # finding the process via its module name...
        Process.whereis(BinanceExchange)
      )

    assign(socket, date: time)
  end
end

defmodule XestWeb.BinanceLive do
  use XestWeb, :live_view

  require Logger
  require Xest

  # Idea : https://medium.com/grandcentrix/state-management-with-phoenix-liveview-and-liveex-f53f8f1ec4d7

  @impl true
  def mount(_params, session, socket) do
    # connection or refresh
    Logger.debug("Binance liveview mount with token: " <> session["_csrf_token"])

    socket =
      case connected?(socket) do
        # first time, static render
        false ->
          socket
          # assigning now for rendering without assigning the (shadow) clock
          |> assign(now: DateTime.from_unix!(0))
          |> assign(status_msg: "N/A")

        # second time websocket info
        true ->
          # setup a self tick with a second period
          :timer.send_interval(1000, self(), :tick)
          # refresh status every 5 seconds
          :timer.send_interval(5000, self(), :status_refresh)

          socket
          # putting actual server date
          |> put_date()
          |> assign(status_msg: retrieve_status().message)
      end

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  @impl true
  def handle_info(:status_refresh, socket) do
    {:noreply, assign(socket, status_msg: retrieve_status().message)}
  end

  defp retrieve_status() do
    binance_exchange().status(
      # finding the process via its module name...
      Process.whereis(binance_exchange())
    )
  end

  @impl true
  def handle_info(msg, socket) do
    {:noreply, socket |> put_flash(:info, msg)}
  end

  defp put_date(socket) do
    # Abusing socket here to store the clock...
    socket =
      Map.put_new_lazy(
        socket,
        :clock,
        fn ->
          binance_exchange().servertime(
            # finding the process via its module name...
            Process.whereis(binance_exchange())
          )
        end
      )

    # compute now
    # We keep clock and now in the assign,
    #    because we want to minimize work on the frontend at the moment
    assign(socket, now: Xest.ShadowClock.now(socket.clock))
  end

  defp binance_exchange() do
    Application.get_env(:xest_web, :binance_exchange)
  end
end

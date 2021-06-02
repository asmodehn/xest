defmodule XestWeb.KrakenLive do
  use XestWeb, :live_view

  require Logger
  require Xest

  # Idea : https://medium.com/grandcentrix/state-management-with-phoenix-liveview-and-liveex-f53f8f1ec4d7

  @impl true
  def mount(_params, session, socket) do
    # connection or refresh
    Logger.debug("Kraken liveview mount with token: " <> session["_csrf_token"])

    socket =
      case connected?(socket) do
        # first time, static render
        false ->
          socket
          # assigning now for rendering without assigning the (shadow) clock
          |> assign(status_msg: "N/A")

        # second time websocket info
        true ->
          # refresh status every 5 seconds
          :timer.send_interval(5000, self(), :status_refresh)

          # also call right now to return updated socket.
          handle_info(:status_refresh, socket) |> elem(1)
      end

    {:ok, socket}
  end

  defp exchange() do
    # indirection to allow mock during tests
    Application.get_env(:xest_web, :exchange, Xest.Exchange)
  end

  @impl true
  def handle_info(:status_refresh, socket) do
    %Xest.Exchange.Status{description: descr} = exchange().status(:kraken)
    {:noreply, assign(socket, status_msg: descr)}
  end

  @impl true
  def handle_info(msg, socket) do
    {:noreply, socket |> put_flash(:info, msg)}
  end
end

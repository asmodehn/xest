defmodule XestWeb.BinanceLive do
  use XestWeb, :live_view

  require Logger
  require Xest

  @impl true
  def mount(_params, session, socket) do
    # connection or refresh
    Logger.debug("Binance liveview mount with token: " <> session["_csrf_token"])

    # setup a self tick with a second period
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
          :timer.send_interval(1000, self(), :tick)

          # subscribe to the binance topic

          :ok = XestWeb.Endpoint.subscribe("binance:requests")
          :ok = XestWeb.Endpoint.subscribe("binance:time")
          :ok = XestWeb.Endpoint.subscribe("binance:system_status")

          socket
          # putting actual server date
          |> put_date()
          # TODO
          |> assign(status_msg: "requesting...")
      end

    IO.inspect(socket)

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  @impl true
  def handle_info(msg, socket) do
    IO.puts("IN HANDLE RANDOM MSG: " <> msg)
    {:noreply, socket |> put_flash(:warning, msg)}
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
      binance_exchange().status(
        # finding the process via its module name...
        Process.whereis(binance_exchange())
      )

    Logger.info("status: #{inspect(status)}")

    {:noreply, assign(socket, status_msg: status.message)}
  end

  defp put_date(socket) do
    Logger.debug("get date")

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
    assign(socket, now: Xest.ShadowClock.now(socket.clock))
  end

  defp binance_exchange() do
    Application.get_env(:xest_web, :binance_exchange)
  end
end

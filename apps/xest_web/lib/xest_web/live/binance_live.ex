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
          # initial balance model
          |> assign(account_balances: [%{}])

        # second time websocket info
        true ->
          # setup a self tick with a second period
          :timer.send_interval(1000, self(), :tick)
          # refresh status every 5 seconds
          :timer.send_interval(5000, self(), :status_refresh)
          # refresh account every 10 seconds
          :timer.send_interval(10_000, self(), :account_refresh)

          socket =
            socket
            # putting actual server date
            |> put_date()
            |> assign(account_balances: filter_null_balances(retrieve_account()))

          # also call right now to return updated socket.
          handle_info(:status_refresh, socket) |> elem(1)
      end

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  # NEW design...
  @impl true
  def handle_info(:status_refresh, socket) do
    %Xest.Exchange.Status{description: descr} = exchange().status(:binance)
    {:noreply, assign(socket, status_msg: descr)}
  end

  #### OLD design, TODO:  integrate with Xest
  @impl true
  def handle_info(:account_refresh, socket) do
    {:noreply,
     assign(socket,
       account_balances: filter_null_balances(retrieve_account())
     )}
  end

  @impl true
  def handle_info(msg, socket) do
    {:noreply, socket |> put_flash(:info, msg)}
  end

  defp retrieve_account() do
    binance_account().account(
      # finding the process via its module name...
      Process.whereis(binance_account())
    )
  end

  defp filter_null_balances(account) do
    account.balances
    # TODO : this filter should probably be done at a lower level
    |> Enum.filter(fn b ->
      {free, ""} = Float.parse(b["free"])
      {locked, ""} = Float.parse(b["locked"])
      Float.round(free, 8) != 0 or Float.round(locked, 8) != 0
    end)
  end

  defp put_date(socket) do
    # Abusing socket here to store the clock...
    # to improve : web page local clock, driven by javascript
    assign(socket, now: clock().utc_now(:binance))
  end

  defp binance_account() do
    Application.get_env(:xest_web, :binance_account)
  end

  defp exchange() do
    # indirection to allow mock during tests
    Application.get_env(:xest_web, :exchange, Xest.Exchange)
  end

  defp clock() do
    # indirection to allow mock during tests
    Application.get_env(:xest_web, :clock, Xest.Clock)
  end
end

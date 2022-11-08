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
          |> assign(account_balances: account_balances())
          # TODO : organise tradables by currency in balances...
          |> assign(account_tradables: account_tradables())

        # second time websocket info
        true ->
          # setup a self tick with a second period
          with {:ok, _} <- :timer.send_interval(1000, self(), :tick),
               # refresh status every 5 seconds
               {:ok, _} <- :timer.send_interval(5000, self(), :status_refresh),
               # refresh account every 10 seconds
               {:ok, _} <- :timer.send_interval(10_000, self(), :account_refresh) do
            socket =
              socket
              # putting actual server date
              |> put_date()
              |> assign(%{account_balances: account_balances(xest_account())})
              # TODO : organise tradables by currency in balances...
              |> assign(account_tradables: account_tradables(xest_account()))

            # also call right now to return updated socket.
            handle_info(:status_refresh, socket) |> elem(1)
          end
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
       account_balances: account_balances(xest_account())
     )}
  end

  @impl true
  def handle_info(msg, socket) do
    {:noreply, socket |> put_flash(:info, msg)}
  end

  def account_balances() do
    Xest.Account.Balance.new().balances
  end

  # TODO : type on account arg
  def account_balances(account) do
    account.balance(:binance).balances
    # TODO : this filter should probably be done at a lower level
    #  and enforced properly with types(careful with floats and precision)...
    |> Enum.filter(fn b ->
      {free, ""} = Float.parse(b.free)
      {locked, ""} = Float.parse(b.locked)
      Float.round(free, 8) != 0 or Float.round(locked, 8) != 0
    end)
  end

  defp put_date(socket) do
    # Abusing socket here to store the clock...
    # to improve : web page local clock, driven by javascript
    assign(socket, now: clock().utc_now(:binance))
  end

  def account_tradables() do
    # TODO : get tradables for all accounts, directly from exchange (?)

    Xest.Account.Balance.new().balances
    # add matching symbols for buy or sell
    |> Enum.into(%{}, fn b ->
      {b.asset,
       [
         buy:
           Enum.filter(exchange().symbols(:binance), fn
             s -> String.ends_with?(s, b.asset)
           end),
         sell:
           Enum.filter(exchange().symbols(:binance), fn
             s -> String.starts_with?(s, b.asset)
           end)
       ]}
    end)
  end

  def account_tradables(account) do
    # get all balances (even the ones at 0.00)
    account.balance(:binance).balances
    # add matching symbols for buy or sell
    |> Enum.into(%{}, fn b ->
      {b.asset,
       [
         buy:
           Enum.filter(exchange().symbols(:binance), fn
             s -> String.ends_with?(s, b.asset)
           end),
         sell:
           Enum.filter(exchange().symbols(:binance), fn
             s -> String.starts_with?(s, b.asset)
           end)
       ]}
    end)
  end

  defp xest_account() do
    Application.get_env(:xest, :account, Xest.Account)
  end

  defp exchange() do
    # indirection to allow mock during tests
    Application.get_env(:xest, :exchange, Xest.Exchange)
  end

  defp clock() do
    # indirection to allow mock during tests
    Application.get_env(:xest, :clock, Xest.Clock)
  end
end

defmodule XestWeb.TradesLive do
  use XestWeb, :live_view

  require Logger
  require Xest
  alias XestWeb.ExchangeParam
  alias XestWeb.SymbolParam

  @impl true
  def render(assigns) do
    ~L"""
    <div>
      <table>
      <tr>
        <%= for h <- @account_transactions |> List.first([nothing: "at_all"]) |> Keyword.keys() do %>
        <th><%= h %></th>
        <% end %>
      </tr>
      <%= for t <- @account_transactions do %>
      <tr>
        <%= for v <- t |> Keyword.values() do %>
        <td><%= v %></td>
        <% end %>
      </tr>
      <% end %>
      </table>

    </div>
    """
  end

  # Idea : https://medium.com/grandcentrix/state-management-with-phoenix-liveview-and-liveex-f53f8f1ec4d7

  @impl true
  def mount(params, session, socket) do
    # connection or refresh
    Logger.debug("Binance liveview mount with token: " <> session["_csrf_token"])

    socket =
      case connected?(socket) do
        # first time, static render
        false ->
          socket
          # initial transactions
          |> assign_trades()
          |> ExchangeParam.assign_exchange(params)
          |> SymbolParam.assign_symbol(params)

        # second time websocket info
        true ->
          with {:ok, _} <- :timer.send_interval(10_000, self(), :account_refresh) do
            socket =
              socket
              |> ExchangeParam.assign_exchange(params)
              |> SymbolParam.assign_symbol(params)
              |> assign_trades()

            # also call right now to return updated socket.
            handle_info(:status_refresh, socket) |> elem(1)
          end
      end

    {:ok, socket}
  end

  def assign_trades(socket) do
    trades =
      case socket.assigns do
        %{exchange: exchg, symbol: symbol} -> retrieve_transactions(exchg, symbol)
        # retrieve all symbols
        %{exchange: exchg} -> retrieve_transactions(exchg)
        # fallback no exchange -> no trades
        _ -> []
      end

    socket |> assign(account_transactions: trades)
  end

  @impl true
  def handle_info(:account_refresh, socket) do
    {:noreply, socket |> assign_trades()}
  end

  @impl true
  def handle_info(msg, socket) do
    {:noreply, socket |> put_flash(:info, msg)}
  end

  # TODO : review this
  defp retrieve_transactions(exchg) do
    xest_account().transactions(exchg).history
    |> Enum.map(fn {id, t} -> [id: id] ++ (Map.from_struct(t) |> Map.to_list()) end)
  end

  defp retrieve_transactions(exchg, symbol) do
    xest_account().transactions(exchg, symbol).history
    |> Enum.map(fn {id, t} -> [id: id] ++ (Map.from_struct(t) |> Map.to_list()) end)
  end

  defp xest_account() do
    Application.get_env(:xest, :account, Xest.Account)
  end
end

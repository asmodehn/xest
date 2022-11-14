defmodule XestWeb.AssetsLive do
  use XestWeb, :live_view
  # TODO : live components instead ??

  require Logger
  require Xest
  alias XestWeb.ExchangeParam

  @impl true
  def render(assigns) do
    ~H"""
    <.container>
      <ul>
      <%= for b <- @account_balances do %>
        <li> <%= b.asset %> <%= if Map.has_key?(b, :free), do: b.free %> <%= if Map.has_key?(b, :locked), do: "(Locked: #{b.locked})" %>

          <table>
            <tr><td> Quote</td>
              <%= for t <- @account_tradables[b.asset][:buy] do %>
              <td> <a href={"binance/#{t}"}><%= t %></a> </td>
              <% end %>
            </tr>
            <tr><td> Base</td>
              <%= for t <- @account_tradables[b.asset][:sell] do %>
              <td> <a href={"binance/#{t}"}><%= t %></a> </td>
              <% end %>
            </tr>
          </table>

      </li>

      <% end %>
      </ul>
    </.container>
    """
  end

  # Idea : https://medium.com/grandcentrix/state-management-with-phoenix-liveview-and-liveex-f53f8f1ec4d7

  @impl true
  def mount(params, session, socket) do
    # connection or refresh
    Logger.debug("Assets liveview mount with token: " <> session["_csrf_token"])

    Logger.debug(
      "requested for: " <>
        Enum.map_join(params, ", ", fn {key, val} -> ~s{"#{key}", "#{val}"} end)
    )

    socket =
      case connected?(socket) do
        # first time, static render
        false ->
          socket
          # initial balance model
          |> assign_balances()
          |> assign_tradables()
          |> ExchangeParam.assign_exchange(params)

        # second time websocket info
        true ->
          # refresh account every 10 seconds
          with {:ok, _} <- :timer.send_interval(10_000, self(), :account_refresh) do
            socket
            |> ExchangeParam.assign_exchange(params)
            |> assign_balances()
            # TODO : organise tradables by currency in balances...
            |> assign_tradables()
          end
      end

    {:ok, socket}
  end

  @impl true
  def handle_info(:account_refresh, socket) do
    {:noreply, socket |> assign_balances()}
  end

  @impl true
  def handle_info(msg, socket) do
    {:noreply, socket |> put_flash(:info, msg)}
  end

  def assign_balances(socket) do
    case socket.assigns do
      %{exchange: exchg} ->
        %Xest.Account.Balance{balances: balances} = xest_account().balance(exchg)
        socket |> assign(account_balances: balances)

      # TODO : maybe add tradables in some data structure representing balances, for easier display in view
      # fallback
      _ ->
        socket |> assign(account_balances: Xest.Account.Balance.new().balances)
    end
  end

  def assign_tradables(socket) do
    tradables =
      case socket.assigns do
        %{exchange: exchg} ->
          # get all balances (even the ones at 0.00)
          xest_account().balance(exchg).balances
          # add matching symbols for buy or sell
          |> Enum.into(%{}, fn b -> symbol_quote_base_correspondence(exchg, b.asset) end)

        # fallback
        _ ->
          Xest.Account.Balance.new().balances
          # no exchange -> se cannot retrieve tradable symbols
          |> Enum.into(%{})
      end

    socket |> assign(account_tradables: tradables)
  end

  # TODO : rethink this... symbols is called too many times !!
  defp symbol_quote_base_correspondence(exchg, asset) do
    symbols = exchange().symbols(exchg)

    {asset,
     [
       buy:
         symbols
         |> Enum.filter(fn
           s -> String.ends_with?(s, asset)
         end),
       sell:
         symbols
         |> Enum.filter(fn
           s -> String.starts_with?(s, asset)
         end)
     ]}
  end

  defp exchange() do
    # indirection to allow mock during tests
    Application.get_env(:xest, :exchange, Xest.Exchange)
  end

  defp xest_account() do
    Application.get_env(:xest, :account, Xest.Account)
  end
end

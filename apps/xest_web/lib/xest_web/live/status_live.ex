defmodule XestWeb.StatusLive do
  use XestWeb, :live_view
  # TODO : live components instead ??

  require Logger
  require Xest
  alias XestWeb.ExchangeParam

  @impl true
  def render(assigns) do
    # assign default value to exchange if one not present
    assigns = Map.put_new(assigns, :exchange, "??")

    ~H"""
    <.container>
      <h1>Hello <%= @exchange %> !</h1>
      <p>Status: <%= @status_msg %></p>
      <p>Server Clock: <%= Calendar.strftime(@now, "%H:%M:%S") %></p>
    </.container>
    """
  end

  @impl true
  def mount(params, session, socket) do
    # connection or refresh
    Logger.debug("status liveview mount with token: " <> session["_csrf_token"])

    Logger.debug(
      "requested for: " <>
        Enum.map_join(params, ", ", fn {key, val} -> ~s{"#{key}", "#{val}"} end)
    )

    #    with {:ok, valid_params} <- Tarams.cast(params, @valid_params) do

    socket =
      case connected?(socket) do
        # first time, static render
        false ->
          socket
          # assigning now for rendering without assigning the (shadow) clock
          |> assign_status_msg()
          |> assign_now()
          # retrieve exchange from the valid params
          # AFTER setting other assigns for first render
          |> ExchangeParam.assign_exchange(params)

        # second time websocket info
        # TODO : Process.send_after(self(), 30_000, :work) is probably better
        true ->
          with {:ok, _} <- :timer.send_interval(1000, self(), :tick),
               # refresh status every 5 seconds
               {:ok, _} <- :timer.send_interval(5000, self(), :status_refresh) do
            # putting actual server date
            socket
            # retrieve exchange from the valid params BEFORE other assigns
            |> ExchangeParam.assign_exchange(params)
            |> assign_now()
            |> assign_status_msg()
          end
      end

    {:ok, socket}
  end

  @impl true
  def handle_info(:status_refresh, socket) do
    {:noreply, assign_status_msg(socket)}
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, assign_now(socket)}
  end

  @impl true
  def handle_info(msg, socket) do
    {:noreply, socket |> put_flash(:info, msg)}
  end

  defp assign_now(socket) do
    IO.inspect(socket.assigns)

    case socket.assigns do
      %{exchange: exchange} ->
        # Abusing socket here to store the clock...
        # to improve : web page local clock, driven by javascript
        assign(socket, now: clock().utc_now(exchange))

      # fallback
      _ ->
        assign(socket, now: clock().utc_now())
    end
  end

  defp assign_status_msg(socket) do
    case socket.assigns do
      %{exchange: exchange} ->
        %Xest.Exchange.Status{description: descr} = exchange().status(exchange)
        assign(socket, status_msg: descr)

      # fallback
      _ ->
        assign(socket, status_msg: "N/A")
    end
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

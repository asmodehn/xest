defmodule XestWeb.StatusLive do
  use XestWeb, :live_view

  require Logger
  require Xest
  #  require Tarams

  # Idea : https://medium.com/grandcentrix/state-management-with-phoenix-liveview-and-liveex-f53f8f1ec4d7

  #  def supported_exchange(exchange) do
  #    case exchange do
  #      okv when okv in ["binance", "kraken"] -> {:ok, String.to_existing_atom(okv)}
  #      _ -> {:error, exchange <> " is not a supported exchange"}
  #    end
  #  end
  #
  #  #TODO : use a separate status live page for aggregated exchange status.
  #  #  Currently using the same page as a first draft... => param not required
  #  @valid_params  %{
  #    # Note: by default, changes the map keys from string to atom.
  #    exchange: [
  #      type: :string, required: false,
  #      cast_func: &__MODULE__.supported_exchange/1  # TODO : fix need to pass public function to tarams macro ??
  #    ],
  #  }

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
          |> assign_exchange(params)

        # second time websocket info
        # TODO : Process.send_after(self(), 30_000, :work) is probably better
        true ->
          with {:ok, _} <- :timer.send_interval(1000, self(), :tick),
               # refresh status every 5 seconds
               {:ok, _} <- :timer.send_interval(5000, self(), :status_refresh) do
            # putting actual server date
            socket
            # retrieve exchange from the valid params BEFORE other assigns
            |> assign_exchange(params)
            |> assign_now()
            |> assign_status_msg()
          end
      end

    {:ok, socket}
    #    else
    #      {:error, errors} ->
    #        # redirect and return params error
    #        {:ok, redirect(socket
    #                       |> put_flash(:error,
    #                         errors |> Enum.map_join(", ", fn {key, val} -> ~s{"#{key}", "#{val}"} end)
    #                       ), to: "/status")}
    #    end
  end

  def assign_exchange(socket, params) do
    case params do
      %{"exchange" => exchange} when exchange in ["binance", "kraken"] ->
        # assign exchange to socket if valid, otherwise redirects
        socket |> assign(exchange: String.to_existing_atom(exchange))

      %{"exchange" => exchange} ->
        redirect(socket |> put_flash(:error, exchange <> " is not a supported exchange"),
          to: "/status"
        )

      _ ->
        socket |> put_flash(:error, "exchange uri param not found")
    end
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

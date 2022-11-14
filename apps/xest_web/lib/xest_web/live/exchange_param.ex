defmodule XestWeb.ExchangeParam do
  @moduledoc false

  alias Phoenix.LiveView

  def assign_exchange(socket, params) do
    case params do
      %{"exchange" => exchange} when exchange in ["binance", "kraken"] ->
        # assign exchange to socket if valid, otherwise redirects
        socket |> LiveView.assign(exchange: String.to_existing_atom(exchange))

      %{"exchange" => exchange} ->
        LiveView.redirect(
          socket |> LiveView.put_flash(:error, exchange <> " is not a supported exchange"),
          to: "/status"
        )

      _ ->
        socket |> LiveView.put_flash(:error, "exchange uri param not found")
    end
  end
end

defmodule XestWeb.ExchangeParam do
  @moduledoc false

  use Phoenix.LiveView

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
end

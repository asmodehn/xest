defmodule XestWeb.SymbolParam do
  @moduledoc false

  use Phoenix.LiveView

  def assign_symbol(socket, params) do
    case params do
      %{"symbol" => symbol} ->
        # assign exchange to socket if valid, otherwise redirects
        socket |> assign(symbol: symbol)

      _ ->
        socket |> put_flash(:error, "symbol uri param not found")
    end
  end
end

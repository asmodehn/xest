defmodule XestWeb.SymbolParam do
  @moduledoc false

  import Phoenix.Component
  alias Phoenix.LiveView

  def assign_symbol(socket, params) do
    case params do
      %{"symbol" => symbol} ->
        # assign exchange to socket if valid, otherwise redirects
        socket |> assign(symbol: symbol)

      _ ->
        socket |> LiveView.put_flash(:error, "symbol uri param not found")
    end
  end
end

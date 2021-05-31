defmodule XestKraken.Models.Exchange do
  defstruct status: %XestKraken.Adapter.SystemStatus{}

  def update(exchange, update_fields \\ []) do
    # TODO : some quick dynamic type check ?
    update_fields
    |> Enum.reduce(exchange, fn {f, v}, m -> Map.replace(m, f, v) end)
  end
end

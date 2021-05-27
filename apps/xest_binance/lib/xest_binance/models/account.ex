defmodule XestBinance.Models.Account do
  defstruct account: %Binance.Account{}

  def update(account, update_fields \\ []) do
    # TODO : some quick dynamic type check ?
    update_fields
    |> Enum.reduce(account, fn {f, v}, m -> Map.replace(m, f, v) end)
  end
end

defmodule XestBinance.Adapter.Behaviour do
  @moduledoc """
    this behaviour is useful for testing with a mock and
    decouple this code from the actual implementation
  """

  alias XestBinance.Adapter.Client

  @type reason :: String.t()

  # | {:error, reason}
  @callback system_status(Client.t()) :: {:ok, %Binance.SystemStatus{}}
  # | {:error, reason}
  @callback ping(Client.t()) :: {:ok, %{}}
  # | {:error, reason}
  @callback servertime(Client.t()) :: {:ok, DateTime.t()}
  # | {:error, reason}
  # TODO : refine
  @callback trades(Client.t(), String.t()) :: {:ok, any()}
  # | {:error, reason}
  @callback account(Client.t()) :: {:ok, %Binance.Account{}}
  # | {:error, reason}
  @callback all_prices(Client.t()) :: {:ok, %Binance.SymbolPrice{}}
end

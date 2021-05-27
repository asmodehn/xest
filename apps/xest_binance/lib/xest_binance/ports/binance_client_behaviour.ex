defmodule XestBinance.Ports.ClientBehaviour do
  @moduledoc """
    this implements a direct conversion from Binance API into Elixir
  """

  # TODO : Matching our internal models for binance data
  #        (close to a subset of Binance.ex models)

  @type binance :: Map.t()

  @type reason :: String.t()
  @type pong :: %{}

  @type servertime :: DateTime.t()

  # | {:error, reason}
  @callback system_status(binance) :: {:ok, %Binance.SystemStatus{}}
  # | {:error, reason}
  @callback ping(binance) :: {:ok, pong}
  # | {:error, reason}
  @callback time(binance) :: {:ok, servertime}
  # | {:error, reason}
  @callback account(binance) :: {:ok, %Binance.Account{}}
end

defmodule XestBinance.Ports.ClientBehaviour do
  @moduledoc """
    this implements a direct conversion from Binance API into Elixir
  """

  # TODO : Matching our internal models for binance data
  #        (close to a subset of Binance.ex models)

  @type status :: XestBinance.Models.ExchangeStatus.t()
  @type reason :: String.t()
  @type pong :: %{}

  @type servertime :: DateTime.t()

  # | {:error, reason}
  @callback system_status() :: {:ok, status}
  # | {:error, reason}
  @callback ping() :: {:ok, pong}
  # | {:error, reason}
  @callback time() :: {:ok, servertime}
end

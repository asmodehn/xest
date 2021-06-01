defmodule XestKraken.Adapter.Behaviour do
  @moduledoc """
    this behaviour is useful for testing with a mock and
    decouple this code from the actual implementation
  """

  alias XestKraken.Adapter.Client

  @type reason :: String.t()
  @type pong :: %{}

  #  @type servertime :: DateTime.t()

  # | {:error, reason}
  @callback system_status(Client.t()) :: {:ok, map()}
  # | {:error, reason}
  #  @callback ping(binance) :: {:ok, pong}
  # NO PING IN KRAKEN API ??

  # | {:error, reason}
  #  @callback time(binance) :: {:ok, servertime}
  # | {:error, reason}
  #  @callback account(binance) :: {:ok, %Binance.Account{}}
end

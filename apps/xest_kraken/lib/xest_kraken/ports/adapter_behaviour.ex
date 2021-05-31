defmodule XestKraken.Ports.AdapterBehaviour do
  @moduledoc """
    this implements a direct conversion from Kraken API into Elixir
  """

  # TODO : Matching our internal models for binance data
  #        (close to a subset of Krakex models)

  @type kraken :: Krakex.Client.t()

  @type reason :: String.t()
  @type pong :: %{}

  @type servertime :: DateTime.t()

  # | {:error, reason}
  @callback system_status(kraken) :: {:ok, Map.t()}
  # | {:error, reason}
  #  @callback ping(binance) :: {:ok, pong}
  # NO PING IN KRAKEN API ??

  # | {:error, reason}
  #  @callback time(binance) :: {:ok, servertime}
  # | {:error, reason}
  #  @callback account(binance) :: {:ok, %Binance.Account{}}
end

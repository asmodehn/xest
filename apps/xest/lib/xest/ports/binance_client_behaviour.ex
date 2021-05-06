defmodule Xest.Ports.BinanceClientBehaviour do
  @moduledoc """
    this implements a direct conversion from Binance API into Elixir
  """

  # TODO : we can refine this to match binance API...
  # %{ required(String.t) => String.t | Int.t }
  @type status :: map
  @type reason :: String.t()
  @type pong :: %{}
  # %{ required(String.t) => String.t }
  @type servertime :: map

  # | {:error, reason}
  @callback system_status() :: {:ok, status}
  # | {:error, reason}
  @callback ping() :: {:ok, pong}
  # | {:error, reason}
  @callback time() :: {:ok, servertime}
end

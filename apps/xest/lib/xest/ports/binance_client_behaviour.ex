defmodule Xest.Ports.BinanceClientBehaviour do

  # TODO : we can refine this to match binance API...
  @type status :: map  # %{ required(String.t) => String.t | Int.t }
  @type reason :: String.t
  @type pong :: %{}
  @type servertime :: map # %{ required(String.t) => String.t }

  @callback system_status() :: {:ok, status} #| {:error, reason}
  @callback ping() :: {:ok, pong} #| {:error, reason}
  @callback time() :: {:ok, servertime} #| {:error, reason}
end
# TODO : move this to domain with the models...
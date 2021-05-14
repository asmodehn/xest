defmodule XestBinance.Ports.ServerBehaviour do
  @moduledoc """
    this implements a conversion from Binance model into our Xest model.
    It serves to specify the types that must be exposed by a GenServer,
    where a better type can provide useful semantics.
    But it remains tied to the Binance model in its overall structure.
  """

  @type status :: XestBinance.Models.ExchangeStatus.t()
  @type reason :: String.t()

  @type servertime :: DateTime.t()
  @type mockable_pid :: nil | pid()

  # | {:error, reason}
  @callback system_status(mockable_pid()) :: {:ok, status}

  @callback system_status!(mockable_pid()) :: status

  # | {:error, reason}
  @callback time(mockable_pid()) :: {:ok, servertime}

  @callback time!(mockable_pid()) :: servertime

  # TODO : by leveraging __using__ we could implement default function
  #                                   and their unsafe counterparts maybe ?
end

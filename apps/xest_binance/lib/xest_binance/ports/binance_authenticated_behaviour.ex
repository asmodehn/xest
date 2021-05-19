defmodule XestBinance.Ports.AuthenticatedBehaviour do
  @moduledoc """
    this implements a conversion from Binance model into our Xest model.
    It serves to specify the types that must be exposed by a GenServer,
    where a better type can provide useful semantics.
    But it remains tied to the Binance model in its overall structure.
  """

  # TODO
  @type account :: Map.t()
  @type reason :: String.t()

  @type mockable_pid :: nil | pid()

  # | {:error, reason}
  @callback account(mockable_pid()) :: {:ok, %Binance.Account{}}

  @callback account!(mockable_pid()) :: %Binance.Account{}

  # TODO : by leveraging __using__ we could implement default function
  #                                   and their unsafe counterparts maybe ?
end

defmodule XestKraken.Adapter.Behaviour do
  @moduledoc """
    this behaviour is useful for testing with a mock and
    decouple this code from the actual implementation
  """

  alias XestKraken.Adapter.Client

  @type reason :: String.t()

  # Note : we use atom for keys, in order to use typing to check map structure

  # | {:error, reason}
  @callback system_status(Client.t()) :: {:ok, %{status: String.t(), timestamp: DateTime.t()}}
  # | {:error, reason}
  #  @callback ping(kraken) :: {:ok, pong}
  # NO PING IN KRAKEN API ??

  #   | {:error, reason}
  @callback servertime(Client.t()) :: {:ok, %{unixtime: DateTime.t(), rfc1123: String.t()}}

  # | {:error, reason}
  #  @callback account(kraken) :: {:ok, %Kraken.Account{}}
end

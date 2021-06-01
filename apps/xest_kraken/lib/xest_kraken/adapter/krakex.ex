defmodule XestKraken.Adapter.Krakex do
  @moduledoc """
    Adapter module using Krakex package,
    converting raw data to elixir data.
  """
  @behaviour XestKraken.Adapter.Behaviour

  require Krakex

  alias XestKraken.Adapter.Client

  @impl true
  def system_status(%Client{impl: client}) do
    Krakex.system_status(client)
  end

  #
  #  @impl true
  #  def time(%Binance{} = binance) do
  #    # needed translating to our pre-existing behaviour...
  #    case Binance.get_server_time(binance) do
  #      {:ok, servertime_ms} -> {:ok, servertime_ms |> DateTime.from_unix!(:millisecond)}
  #      {:error, reason} -> {:error, reason}
  #    end
  #  end
  #
  #  @impl true
  #  def account(%Binance{} = binance) do
  #    Binance.get_account(binance)
  #  end
end

defmodule XestBinance.Adapter.Binance do
  @moduledoc """
    Adapter module using Binance package
  """
  @behaviour XestBinance.Adapter.Behaviour

  require Binance

  @impl true
  def system_status(%XestBinance.Adapter.Client{impl: binance}) do
    case Binance.get_system_status(binance) do
      {:ok, status} -> {:ok, status}
      {:error, err} -> {:error, err}
    end
  end

  @impl true
  def ping(%XestBinance.Adapter.Client{impl: binance}) do
    Binance.ping(binance)
  end

  @impl true
  def servertime(%XestBinance.Adapter.Client{impl: binance}) do
    # needed translating to our pre-existing behaviour...
    case Binance.get_server_time(binance) do
      {:ok, servertime_ms} -> {:ok, servertime_ms |> DateTime.from_unix!(:millisecond)}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def account(%XestBinance.Adapter.Client{impl: binance}) do
    Binance.get_account(binance)
  end
end

defmodule XestBinance.Client do
  @moduledoc """
    Adapter module using Binance package
  """
  @behaviour XestBinance.Ports.ClientBehaviour

  require Binance

  @impl true
  def system_status() do
    # TEMPORARY, until integrated in Binance
    case Binance.Rest.HTTPClient.get_binance("/wapi/v3/systemStatus.html") do
      {:ok, %{"msg" => msg, "status" => status}} ->
        {:ok, %XestBinance.Models.ExchangeStatus{message: msg, code: status}}

      err ->
        err
    end
  end

  @impl true
  def ping() do
    Binance.ping()
  end

  @impl true
  def time() do
    # needed translating to our pre-existing behaviour...
    case Binance.get_server_time() do
      {:ok, servertime_ms} -> {:ok, servertime_ms |> DateTime.from_unix!(:millisecond)}
      {:error, reason} -> {:error, reason}
    end
  end

  #
  #  defp endpoint() do
  #    Application.get_env(:binance, :end_point, "https://api.binance.com")
  #  end
end

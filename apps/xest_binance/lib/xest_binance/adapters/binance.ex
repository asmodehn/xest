defmodule XestBinance.Client do
  @moduledoc """
    Adapter module using Binance package
  """
  @behaviour XestBinance.Ports.ClientBehaviour

  require Binance

  def new(apikey \\ nil, secret \\ nil, endpoint \\ "https://api.binance.com") do
    %Binance{endpoint: endpoint, api_key: apikey, secret_key: secret}
  end

  @impl true
  def system_status(%Binance{} = binance) do
    # TEMPORARY, until integrated in Binance
    case Binance.Rest.HTTPClient.get_binance(binance.endpoint <> "/wapi/v3/systemStatus.html") do
      {:ok, %{"msg" => msg, "status" => status}} ->
        {:ok, %XestBinance.Models.ExchangeStatus{message: msg, code: status}}

      err ->
        err
    end
  end

  @impl true
  def ping(%Binance{} = binance) do
    Binance.ping(binance)
  end

  @impl true
  def time(%Binance{} = binance) do
    # needed translating to our pre-existing behaviour...
    case Binance.get_server_time(binance) do
      {:ok, servertime_ms} -> {:ok, servertime_ms |> DateTime.from_unix!(:millisecond)}
      {:error, reason} -> {:error, reason}
    end
  end

  def get_account(%Binance{} = binance) do
    Binance.get_account(binance)
  end
end
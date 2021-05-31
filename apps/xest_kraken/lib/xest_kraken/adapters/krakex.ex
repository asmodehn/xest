defmodule XestKraken.Krakex do
  @moduledoc """
    Adapter module using Binance package
  """
  @behaviour XestKraken.Ports.AdapterBehaviour

  require Krakex

  def new(apikey \\ nil, secret \\ nil, endpoint \\ nil) do
    client =
      case {apikey, secret} do
        {nil, _} ->
          Krakex.API.public_client()

        {_, nil} ->
          Krakex.API.public_client()
          #        {key, secret} -> Kraken.API.private_client()  # TODO : fix
      end

    if endpoint != nil do
      Map.put(client, :endpoint, endpoint)
    else
      client
    end
  end

  @impl true
  def system_status(%Krakex.Client{} = client) do
    case Krakex.system_status(client) do
      {:ok, status} -> {:ok, status}
      {:error, err} -> {:error, err}
      other -> IO.inspect(other)
    end
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

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
    case Krakex.system_status(client) do
      {:ok, response} ->
        atom_resp = response |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)
        {:ok, tsz, 0} = DateTime.from_iso8601(atom_resp[:timestamp])
        {:ok, %{atom_resp | timestamp: tsz}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def servertime(%Client{impl: client}) do
    case Krakex.server_time(client) do
      {:ok, response} ->
        atom_resp = response |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)
        {:ok, %{atom_resp | unixtime: DateTime.from_unix!(atom_resp[:unixtime], :second)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def balance(%Client{impl: client}) do
    case Krakex.balance(client) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def trades(%Client{impl: client}, offset \\ 0) do
    case Krakex.trades_history(client, offset) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def asset_pairs(%Client{impl: client}) do
    case Krakex.asset_pairs(client) do
      {:ok, response} -> {:ok, response}
      {:error, reason} -> {:error, reason}
    end
  end
end

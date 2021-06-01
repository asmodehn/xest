defmodule XestKraken.Adapter.Client do
  @moduledoc """
      A client model implementation, usable with all implemented adaptors.
      Currently only krakex -> hardcoded here.
  """
  @enforce_keys [:impl]
  defstruct impl: nil

  @typedoc "A client delagate to the adapter client implementation"
  @type t() :: %__MODULE__{
          impl: Krakex.Client.t()
        }

  @spec new(String.t(), String.t(), String.t()) :: %__MODULE__{}
  def new(apikey \\ nil, secret \\ nil, endpoint \\ nil) do
    adapter_client =
      case {apikey, secret} do
        {nil, _} ->
          Krakex.API.public_client()

        {_, nil} ->
          Krakex.API.public_client()
          #        {key, secret} -> Kraken.API.private_client()  # TODO : fix
      end

    if endpoint != nil do
      %__MODULE__{impl: adapter_client |> Map.put(:endpoint, endpoint)}
    else
      %__MODULE__{impl: adapter_client}
    end
  end
end

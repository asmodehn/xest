defmodule XestKraken.Adapter.Client do
  @moduledoc """
      A client model implementation, usable with all implemented adaptors.
      Adaptor implementation stored as part of the client data.
      Currently only krakex -> hardcoded here.
  """
  @enforce_keys [:impl]
  defstruct impl: nil,
            adapter: XestKraken.Adapter.Krakex

  @typedoc "A client delegate to the adapter client implementation"
  @type t() :: %__MODULE__{
          impl: %Krakex.Client{},
          adapter: atom()
        }

  @spec new(apikey :: String.t() | nil, secret :: String.t() | nil, endpoint :: String.t() | nil) ::
          %__MODULE__{}
  def new(apikey \\ nil, secret \\ nil, endpoint \\ nil) do
    adapter_client =
      case {apikey, secret} do
        {nil, _} ->
          Krakex.API.public_client()

        {_, nil} ->
          Krakex.API.public_client()

        {apikey, secret} ->
          Krakex.Client.new(apikey, secret)
      end

    if endpoint != nil do
      %__MODULE__{impl: adapter_client |> Map.put(:endpoint, endpoint)}
    else
      %__MODULE__{impl: adapter_client}
    end
  end

  # useful when we want to pass override the adapter implementation along with the client connexion details
  def with_adapter(%__MODULE__{} = client, adapter \\ XestKraken.Adapter.Krakex) do
    %{client | adapter: adapter}
  end
end

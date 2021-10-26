defmodule XestBinance.Adapter.Client do
  @moduledoc """
      A client model implementation, usable with all implemented adaptors.
      Currently only binance.ex -> hardcoded here.
  """

  require Binance

  @default_endpoint "https://api.binance.com"

  @enforce_keys [:impl]
  defstruct impl: nil,
            adapter: XestBinance.Adapter.Binance

  @typedoc "A client delegate to the adapter client implementation"
  @type t() :: %__MODULE__{
          impl: %Binance{},
          adapter: atom()
        }

  @spec new(String.t() | nil, String.t() | nil, String.t() | nil) :: %__MODULE__{}
  def new(apikey \\ nil, secret \\ nil, endpoint \\ @default_endpoint) do
    %__MODULE__{impl: %Binance{endpoint: endpoint, api_key: apikey, secret_key: secret}}
  end

  # useful when we want to pass override the adapter implementation along with the client connexion details
  def with_adapter(%__MODULE__{} = client, adapter \\ XestBinance.Adapter.Binance) do
    %{client | adapter: adapter}
  end
end

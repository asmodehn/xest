defmodule XestBinance.Adapter.Client do
  @moduledoc """
      A client model implementation, usable with all implemented adaptors.
      Currently only binance.ex -> hardcoded here.
  """

  require Binance

  @default_endpoint "https://api.binance.com"

  @enforce_keys [:impl]
  defstruct impl: nil

  @typedoc "A client delegate to the adapter client implementation"
  @type t() :: %__MODULE__{
          impl: %Binance{}
        }

  @spec new(String.t(), String.t(), String.t()) :: %__MODULE__{}
  def new(apikey \\ nil, secret \\ nil, endpoint \\ @default_endpoint) do
    %__MODULE__{impl: %Binance{endpoint: endpoint, api_key: apikey, secret_key: secret}}
  end
end

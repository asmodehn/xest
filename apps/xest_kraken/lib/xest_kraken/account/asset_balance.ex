defmodule XestKraken.Account.AssetBalance do
  defstruct asset: nil,
            amount: 0.0

  @typedoc "An asset balance"
  @type t() :: %__MODULE__{
          # TODO : refine
          asset: String.t() | nil,
          amount: String.t()
        }

  use ExConstructor
end

defimpl Xest.Account.AssetBalance.ACL, for: XestKraken.Account.AssetBalance do
  def new(%XestKraken.Account.AssetBalance{asset: asset, amount: amount}) do
    Xest.Account.AssetBalance.new(
      asset,
      amount
    )
  end
end

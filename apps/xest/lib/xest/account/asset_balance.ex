defmodule Xest.Account.AssetBalance do
  import Algae

  @moduledoc """
    defines an asset balance with ADT
  """

  defdata do
    asset :: String.t()
    free :: float()
    locked :: float()
  end
end

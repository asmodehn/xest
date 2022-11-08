defmodule Xest.Account.TradesHistory do
  import Algae

  @moduledoc """
    defines a trades history structure with ADT
  """

  defdata do
    history :: %{String.t() => Xest.Account.Trade.t()}
  end
end

# Protocol for each connector to provide an exchange status with the correct format
defprotocol Xest.Account.TradesHistory.ACL do
  @spec new(t) :: Xest.Account.TradesHistory.t()
  def new(value)
end

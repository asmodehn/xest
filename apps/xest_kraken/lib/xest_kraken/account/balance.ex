# Since krakex does not have types for the data returned
# here we define these types and convert from them to the xest representation

defmodule XestKraken.Account.Balance do
  @moduledoc """
  Struct for representing the account current balance.

  This is kraken specific, but not adapter specific.

  ```
  defstruct [:status, :timestamp]
  ```
  """

  # default to maintenance for safety
  defstruct balances: []
  # TODO : maybe add some total amount converted in a specific currency...
  #            total_ref: nil

  @typedoc "A system status data structure"
  @type t() :: %__MODULE__{
          # TODO : refine
          # [XestKraken.Account.AssetBalance.t()]| nil
          balances: list()
        }

  use ExConstructor
end

# providing implementation for Xest ACL
defimpl Xest.Account.Balance.ACL, for: XestKraken.Account.Balance do
  def new(%XestKraken.Account.Balance{balances: balances}) do
    Xest.Account.Balance.new(balances)
  end
end

# Since krakex does not have types for the data returned
# here we define these types and convert from them to the xest representation

defmodule XestKraken.Account.Trades do
  @moduledoc """
  Struct for representing the account past trades.

  This is kraken specific, but not adapter specific.

  """
  defstruct trades: %{}

  @typedoc "A trades data structure"
  @type t() :: %__MODULE__{
          # TODO : refine
          trades: map()
        }

  use ExConstructor
end

# providing implementation for Xest ACL
defimpl Xest.Account.TradesHistory.ACL, for: XestKraken.Account.Trades do
  def new(%XestKraken.Account.Trades{trades: trades}) do
    trades
    |> Enum.map(fn {id, td} ->
      {id, Xest.Account.Trade.ACL.new(td)}
    end)
    |> Enum.into(%{})
    |> Xest.Account.TradesHistory.new()
  end
end

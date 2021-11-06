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

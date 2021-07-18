defmodule XestKraken.Exchange.ServerTime do
  # default to epoch
  defstruct unixtime: DateTime.from_unix!(0),
            rfc1123: nil

  @typedoc "Kraken's servertime data structure"
  @type t() :: %__MODULE__{
          unixtime: DateTime.t(),
          rfc1123: String.t() | nil
        }

  use ExConstructor
end

defimpl Xest.Exchange.ServerTime.ACL, for: XestKraken.Exchange.ServerTime do
  def new(%XestKraken.Exchange.ServerTime{unixtime: unixtime}) do
    Xest.Exchange.ServerTime.new(unixtime)
  end
end

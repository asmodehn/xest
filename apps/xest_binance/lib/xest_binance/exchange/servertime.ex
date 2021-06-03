defmodule XestBinance.Exchange.ServerTime do
  # default to epoch
  defstruct servertime: DateTime.from_unix!(0)

  @typedoc "A system status data structure"
  @type t() :: %__MODULE__{
          # TODO : refine
          servertime: DateTime.t()
        }

  use ExConstructor
end

defimpl Xest.Exchange.ServerTime.ACL, for: XestBinance.Exchange.ServerTime do
  def new(%XestBinance.Exchange.ServerTime{servertime: servertime}) do
    Xest.Exchange.ServerTime.new(servertime)
  end
end

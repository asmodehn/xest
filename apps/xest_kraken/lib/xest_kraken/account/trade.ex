defmodule XestKraken.Account.Trade do
  defstruct cost: 0.0,
            fee: 0.0,
            margin: 0.0,
            misc: "",
            ordertxid: "",
            ordertype: "",
            pair: "",
            postxid: "",
            price: 0.0,
            time: 0.0,
            type: "",
            vol: 0.0

  @typedoc "A trade"
  @type t() :: %__MODULE__{
          # TODO : refine
          cost: float(),
          fee: float(),
          margin: float(),
          misc: String.t(),
          ordertxid: String.t(),
          ordertype: String.t(),
          pair: String.t(),
          postxid: String.t(),
          price: float(),
          time: float(),
          type: String.t(),
          vol: float()
        }

  use ExConstructor
end

# providing implementation for Xest ACL
# TODO

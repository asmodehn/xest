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
defimpl Xest.Account.Trade.ACL, for: XestKraken.Account.Trade do
  def new(%XestKraken.Account.Trade{
        cost: _cost,
        fee: _fee,
        margin: _margin,
        misc: _misc,
        ordertxid: _ordertxid,
        ordertype: _ordertype,
        pair: pair,
        postxid: _postxid,
        price: price,
        time: time,
        type: _type,
        vol: vol
      }) do
    Xest.Account.Trade.new(
      pair,
      price,
      time,
      vol
    )
  end
end

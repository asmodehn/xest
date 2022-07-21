defmodule XestBinance.Exchange.SymbolPrice do
  # Use TypedStruct to import the typedstruct macro.
  use TypedStruct

  # Define your struct.
  typedstruct do
    # Define each field with the field macro.
    field(:symbol, String.t(), enforce: true)
    field(:price, Float.t(), enforce: true)
  end
end

# providing implementation for Xest ACL
defimpl Xest.Exchange.Ticker, for: XestBinance.Exchange.SymbolPrice do
  def symbol(%XestBinance.Exchange.SymbolPrice{symbol: symbol}) do
    symbol
  end

  def price(%XestBinance.Exchange.SymbolPrice{price: price}) do
    price
  end
end

defprotocol Xest.Exchange.Ticker do
  @spec symbol(t) :: String.t()
  def symbol(ticker)

  @spec price(t) :: Float.t()
  def price(ticker)
end

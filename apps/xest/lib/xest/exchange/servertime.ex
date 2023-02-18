# TODO : shadowclock here...
defmodule Xest.Exchange.ServerTime do
  import Algae

  defdata do
    servertime :: XestClock.DateTime.t()
  end
end

# Protocol for each connector to provide an exchange status with the correct format
defprotocol Xest.Exchange.ServerTime.ACL do
  @spec new(t) :: Xest.Exchange.ServerTime.t()
  def new(value)
end

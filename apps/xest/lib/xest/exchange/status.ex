defmodule Xest.Exchange.Status do
  import Algae

  defdata do
    status :: :offline | :online | :maintenance
    description :: String.t()
  end
end

# Protocol for each connector to provide an exchange status with the correct format
defprotocol Xest.Exchange.Status.ACL do
  @spec new(t) :: Xest.Exchange.Status.t()
  def new(value)
end

defmodule Xest.Exchange.Behaviour do
  @callback status(atom()) :: %Xest.Exchange.Status{}
  @callback servertime(atom()) :: %Xest.Exchange.ServerTime{}
end

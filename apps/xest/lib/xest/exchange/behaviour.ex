defmodule Xest.Exchange.Behaviour do
  @callback status(atom()) :: %Xest.Exchange.Status{}
end

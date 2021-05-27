defmodule Xest.ExchangeStatus do
  import Algae

  defdata do
    status :: non_neg_integer()
    message :: String.t()
  end
end

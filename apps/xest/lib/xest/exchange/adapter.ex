defmodule Xest.Exchange.Adapter do
  defp kraken() do
    Application.get_env(:xest, :kraken_exchange)
  end

  def retrieve(:kraken, :status) do
    connector_response =
      kraken().status(
        # finding the process via its module name...
        Process.whereis(kraken())
      )

    Xest.Exchange.Status.ACL.new(connector_response)
  end
end

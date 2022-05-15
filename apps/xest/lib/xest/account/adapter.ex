defmodule Xest.Account.Adapter do
  defp kraken() do
    Application.get_env(:xest, :kraken_account)
  end

  defp binance() do
    Application.get_env(:xest, :binance_account)
  end

  def retrieve(:kraken, :balance) do
    connector_response =
      kraken().balance(
        # looking for process via its name
        Process.whereis(kraken())
      )

    connector_response
  end

  def retrieve(:binance, :balance) do
    connector_response =
      binance().balance(
        # looking for process via its name
        Process.whereis(binance())
      )

    connector_response
  end

  def retrieve(:kraken, :trades) do
    connector_response =
      kraken().trades(
        # looking for process via its name
        Process.whereis(kraken()),
        # TODO : get rid of this somehow...
        ""
      )

    connector_response
  end

  def retrieve(:binance, :trades) do
    connector_response =
      binance().trades(
        # looking for process via its name
        Process.whereis(binance())
      )

    connector_response
  end
end

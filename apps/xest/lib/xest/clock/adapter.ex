defmodule Xest.Clock.Adapter do
  defp kraken() do
    Application.get_env(:xest, :kraken_clock)
  end

  defp binance() do
    Application.get_env(:xest, :binance_clock)
  end

  def retrieve(:kraken, :utc_now) do
    connector_response =
      kraken().utc_now(
        # looking for process via its name
        Process.whereis(kraken())
      )

    # no need for an ACL to convert data here,
    # connector should already use the elixir datatype.
    connector_response
  end

  def retrieve(:binance, :utc_now) do
    connector_response =
      binance().utc_now(
        # looking for process via its name
        Process.whereis(binance())
      )

    # no need for an ACL to convert data here,
    # connector should already use the elixir datatype.
    connector_response
  end
end

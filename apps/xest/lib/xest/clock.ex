defmodule Xest.Clock do
  defmodule Behaviour do
    @moduledoc "Behaviour to allow mocking a xest clock for tests"
    @callback utc_now(atom()) :: DateTime.t()
  end

  def utc_now(:binance) do
    binance().utc_now(
      # finding the process (or nil if mocked)
      Process.whereis(binance())
    )
  end

  def utc_now(:kraken) do
    kraken().utc_now(
      # finding the process (or nil if mocked)
      Process.whereis(kraken())
    )
  end

  defp kraken() do
    Application.get_env(:xest, :kraken_clock)
  end

  defp binance() do
    Application.get_env(:xest, :binance_clock)
  end
end

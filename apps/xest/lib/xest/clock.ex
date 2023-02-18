defmodule Xest.Clock do
  # NOT an alias.
  require XestClock.DateTime
  # In this module the DateTime.t() type is the core Elixir one.

  defmodule Behaviour do
    @moduledoc "Behaviour to allow mocking a xest clock for tests"
    @callback utc_now(atom()) :: DateTime.t()
    @callback utc_now() :: DateTime.t()
  end

  @behaviour Behaviour

  @impl true
  def utc_now() do
    datetime().utc_now()
  end

  @impl true
  def utc_now(:binance) do
    binance().utc_now(
      # finding the process (or nil if mocked)
      Process.whereis(binance())
    )
  end

  @impl true
  def utc_now(:kraken) do
    kraken().utc_now(
      # finding the process (or nil if mocked)
      Process.whereis(kraken())
    )
  end

  defp datetime() do
    Application.get_env(:xest_clock, :datetime_module, XestClock.DateTime)
  end

  defp kraken() do
    Application.get_env(:xest, :kraken_clock)
  end

  defp binance() do
    Application.get_env(:xest, :binance_clock)
  end
end

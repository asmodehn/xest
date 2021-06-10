defmodule Xest.Clock.Adapter.Test do
  use ExUnit.Case, async: true

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "retrieve utc_now from kraken connector" do
    XestKraken.Clock.Mock
    |> expect(:utc_now, fn nil -> ~U[2020-02-02 02:02:02.020Z] end)

    assert Xest.Clock.Adapter.retrieve(:kraken, :utc_now) == ~U[2020-02-02 02:02:02.020Z]
  end

  test "retrieve utc_now from binance connector" do
    XestBinance.Clock.Mock
    |> expect(:utc_now, fn nil -> ~U[2020-02-02 02:02:02.020Z] end)

    assert Xest.Clock.Adapter.retrieve(:binance, :utc_now) == ~U[2020-02-02 02:02:02.020Z]
  end
end

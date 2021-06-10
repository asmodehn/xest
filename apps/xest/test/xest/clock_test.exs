defmodule Xest.Clock.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Clock

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: Xest.Clock, behaviour: Xest.Clock.Behaviour

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox

  describe "For xest_kraken:" do
    test "clock works" do
      XestKraken.Clock.Mock
      |> expect(:utc_now, fn nil ->
        ~U[2020-02-02 02:02:02.202Z]
      end)

      assert Clock.utc_now(:kraken) ==
               ~U[2020-02-02 02:02:02.202Z]
    end
  end

  describe "For xest_binance:" do
    test "clock works" do
      XestBinance.Clock.Mock
      |> expect(:utc_now, fn nil ->
        ~U[2020-02-02 02:02:02.202Z]
      end)

      assert Clock.utc_now(:binance) ==
               ~U[2020-02-02 02:02:02.202Z]
    end
  end
end

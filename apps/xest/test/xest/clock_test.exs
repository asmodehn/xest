defmodule Xest.Clock.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Clock

  @time_stop ~U[2020-02-02 02:02:02.202Z]

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: Xest.Clock, behaviour: Xest.Clock.Behaviour

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox

  describe "For xest_kraken:" do
    test "clock works" do
      XestKraken.Clock.Mock
      |> expect(:utc_now, fn nil -> @time_stop end)

      assert Clock.utc_now(:kraken) == @time_stop
    end
  end

  describe "For xest_binance:" do
    test "clock works" do
      XestBinance.Clock.Mock
      |> expect(:utc_now, fn nil -> @time_stop end)

      assert Clock.utc_now(:binance) == @time_stop
    end
  end

  describe "For local default:" do
    setup do
      Application.put_env(:xest, :datetime_module, Xest.DateTime.Mock)
    end

    test "clock works" do
      Xest.DateTime.Mock
      |> expect(:utc_now, fn -> @time_stop end)

      assert Clock.utc_now() == @time_stop
    end
  end
end

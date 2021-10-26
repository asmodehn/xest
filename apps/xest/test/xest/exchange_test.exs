defmodule Xest.Exchange.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Exchange

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: Xest.Exchange, behaviour: Xest.Exchange.Behaviour

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox

  describe "For xest_kraken:" do
    test "status works" do
      XestKraken.Exchange.Mock
      # nil as pid since we use a mock here
      |> expect(:status, fn nil ->
        %XestKraken.Exchange.Status{}
      end)

      assert Exchange.status(:kraken) == %Xest.Exchange.Status{
               description: "maintenance",
               status: :maintenance
             }
    end
  end

  describe "For xest_binance:" do
    test "status works" do
      XestBinance.Exchange.Mock
      |> expect(:status, fn nil ->
        %XestBinance.Exchange.Status{}
      end)

      assert Exchange.status(:binance) == %Xest.Exchange.Status{
               description: "maintenance",
               status: :maintenance
             }
    end
  end
end

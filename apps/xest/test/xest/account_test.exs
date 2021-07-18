defmodule Xest.Account.Test do
  use ExUnit.Case, async: true

  alias Xest.Account

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox
  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: Xest.Account, behaviour: Xest.Account.Behaviour

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox

  # TODO : pointless tests (enforced by behaviors) -> remove them ?
  describe "For xest_kraken:" do
    test "balance works" do
      XestKraken.Account.Mock
      |> expect(:balance, fn _ ->
        %Account.Balance{balances: []}
      end)

      balance = Account.balance(:kraken)

      assert balance == %Xest.Account.Balance{
               balances: []
             }
    end
  end

  # TODO : pointless tests (enforced by behaviors) -> remove them ?
  describe "For xest_binance:" do
    test "balance works" do
      XestBinance.Account.Mock
      |> expect(:balance, fn _ ->
        # TODO : we shouldn't be depending on binance implementation here...
        %Account.Balance{balances: []}
      end)

      balance = Account.balance(:binance)

      assert balance == %Xest.Account.Balance{
               balances: []
             }
    end
  end
end

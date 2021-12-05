defmodule XestBinance.Account.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias XestBinance.Account
  alias XestBinance.Auth

  import Hammox

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: XestBinance.Account, behaviour: XestBinance.Account.Behaviour

  setup do
    acc_pid =
      start_supervised!({
        Account,
        # passing nil as we rely on a mock here.
        name: String.to_atom("#{__MODULE__}.Process"),
        auth_mod: XestBinance.Auth.Mock,
        auth_pid: nil
      })

    # setting up server mock to test the chain
    # Account -> Agent messaging -> BinanceAuthenticated
    # without relying on a specific server implementation
    Auth.Mock
    |> allow(self(), acc_pid)

    %{acc_pid: acc_pid}
  end

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "retrieve default client account generates default xest account model", %{acc_pid: acc_pid} do
    Auth.Mock
    |> expect(:account, fn _ ->
      {:ok, %Binance.Account{balances: []}}
    end)

    assert Account.balance(acc_pid) ==
             %Xest.Account.Balance{}
  end

  test "retrieve default client trades generates default xest trades history model", %{
    acc_pid: acc_pid
  } do
    Auth.Mock
    |> expect(:trades, fn _, _s ->
      {:ok, []}
    end)

    assert Account.trades(acc_pid, "SOMSYM") ==
             %Xest.Account.TradesHistory{history: %{}}
  end
end

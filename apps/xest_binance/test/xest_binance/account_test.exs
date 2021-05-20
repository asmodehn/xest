defmodule XestBinance.Account.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias XestBinance.Models
  alias XestBinance.Account
  alias XestBinance.AuthenticatedBehaviourMock

  import Hammox

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: XestBinance.Account, behaviour: XestBinance.Ports.AccountBehaviour

  setup do
    # starting server mock process...
    # start_supervised!({BinanceAuthenticatedBehaviourMock, name: String.to_atom("#{__MODULE__}.AuthenticatedProcess")})
    server_pid = nil

    acc_pid =
      start_supervised!({
        Account,
        # passing nil as we rely on a mock here.
        name: String.to_atom("#{__MODULE__}.Process"), authenticated: server_pid
      })

    # setting up server mock to tes the chain
    # Account -> Agent messaging -> BinanceAuthenticated
    # without relying on a specific server implementation
    AuthenticatedBehaviourMock
    |> allow(self(), acc_pid)

    %{server_pid: server_pid, acc_pid: acc_pid}
  end

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "initial value with model nil OK", %{server_pid: server_pid, acc_pid: acc_pid} do
    acc_pid
    |> Account.state()
    |> assert_fields(%{
      model: nil,
      authsrv: server_pid
    })
  end

  test "retrieve default client account generates default xest account model", %{acc_pid: acc_pid} do
    AuthenticatedBehaviourMock
    |> expect(:account, fn _ ->
      {:ok, %Binance.Account{}}
    end)

    assert Account.account(acc_pid) ==
             %Xest.Account{
               # not exposed by binance.ex
               account_type: "",
               balances: nil,
               buyer_commission: nil,
               can_deposit: nil,
               can_trade: nil,
               can_withdrawal: nil,
               maker_commission: nil,
               # not exposed by binance.ex
               permissions: [],
               seller_commission: nil,
               taker_commission: nil,
               update_time: nil
             }

    # Note this reuse model in cache to avoid useless request
    assert Account.account(acc_pid) ==
             %Xest.Account{
               # not exposed by binance.ex
               account_type: "",
               balances: nil,
               buyer_commission: nil,
               can_deposit: nil,
               can_trade: nil,
               can_withdrawal: nil,
               maker_commission: nil,
               # not exposed by binance.ex
               permissions: [],
               seller_commission: nil,
               taker_commission: nil,
               update_time: nil
             }
  end
end

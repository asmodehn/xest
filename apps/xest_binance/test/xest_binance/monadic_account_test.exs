defmodule XestBinance.MonadicAccount.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  #  alias XestBinance.Models
  alias XestBinance.MonadicAccount
  alias XestBinance.AuthenticatedBehaviourMock

  import Hammox

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  #  use Hammox.Protect, module: XestBinance.MonadicAccount, behaviour: XestBinance.Ports.AccountBehaviour

  setup do
    # starting server mock process...
    # start_supervised!({BinanceAuthenticatedBehaviourMock, name: String.to_atom("#{__MODULE__}.AuthenticatedProcess")})
    server_pid = nil

    # UNNEEDED HERE... maybe replace with the actual authenticated server (only one layer of server) ?
    #    acc_pid =
    #      start_supervised!({
    #        Account,
    #        # passing nil as we rely on a mock here.
    #        name: String.to_atom("#{__MODULE__}.Process"), authenticated: server_pid
    #      })

    %{server_pid: server_pid}
  end

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "MonadicAccount is a state monad" do
    # make a new account monad, with only the mock as backend.
    acc = MonadicAccount.new(AuthenticatedBehaviourMock, nil)

    # Note mock hasn't been called yet... and we get a state monad.
    assert %Algae.State{} = acc
  end

  test "account returns only the value, ie. the xest account model" do
    AuthenticatedBehaviourMock
    |> expect(:account, fn _ ->
      {:ok, %Binance.Account{}}
    end)

    DateTimeMock
    |> expect(:utc_now, fn -> ~U[1970-01-01 01:01:01Z] end)

    acc = MonadicAccount.new(AuthenticatedBehaviourMock, nil)

    assert acc |> MonadicAccount.account(&Xest.DateTime.utc_now/0) == %Xest.Account{
             # Binance.Account doesnt have meaningful defaults, only nils.
             account_type: "",
             balances: nil,
             buyer_commission: nil,
             can_deposit: nil,
             can_trade: nil,
             can_withdrawal: nil,
             maker_commission: nil,
             permissions: [],
             seller_commission: nil,
             taker_commission: nil,
             update_time: nil
           }
  end

  test "inspect returns the internal state only" do
    AuthenticatedBehaviourMock
    |> expect(:account, fn _ ->
      {:ok, %Binance.Account{}}
    end)

    DateTimeMock
    |> expect(:utc_now, fn -> ~U[1970-01-01 01:01:01Z] end)

    acc = MonadicAccount.new(AuthenticatedBehaviourMock, nil)

    assert acc |> MonadicAccount.inspect(&Xest.DateTime.utc_now/0) == %MonadicAccount{
             authsrv: AuthenticatedBehaviourMock,
             model: %Xest.Account{
               account_type: "",
               balances: nil,
               buyer_commission: nil,
               can_deposit: nil,
               can_trade: nil,
               can_withdrawal: nil,
               maker_commission: nil,
               permissions: [],
               seller_commission: nil,
               taker_commission: nil,
               update_time: nil
             }
           }
  end
end

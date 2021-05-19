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

  test "initial value OK", %{server_pid: server_pid, acc_pid: acc_pid} do
    acc_pid
    |> Account.state()
    |> assert_fields(%{
      model: %Models.Account{},
      authsrv: server_pid
    })
  end

  test "retrieve account", %{acc_pid: acc_pid} do
    AuthenticatedBehaviourMock
    |> expect(:account, fn _ ->
      {:ok, %Binance.Account{}}
    end)

    acc_pid
    |> Account.account()
    |> assert_fields(%{
      balances: nil,
      buyer_commission: nil,
      can_deposit: nil,
      can_trade: nil,
      can_withdrawl: nil,
      maker_commission: nil,
      seller_commission: nil,
      taker_commission: nil,
      update_time: nil
    })
  end

  test "after retrieving account, state is still usable", %{acc_pid: acc_pid} do
    AuthenticatedBehaviourMock
    |> expect(:account, fn _ ->
      {:ok, %Binance.Account{}}
    end)
    |> expect(:account, fn _ ->
      {:ok, %Binance.Account{}}
    end)

    Account.account(acc_pid)

    acc_pid
    |> Account.account()
    |> assert_fields(%{
      balances: nil,
      buyer_commission: nil,
      can_deposit: nil,
      can_trade: nil,
      can_withdrawl: nil,
      maker_commission: nil,
      seller_commission: nil,
      taker_commission: nil,
      update_time: nil
    })
  end
end

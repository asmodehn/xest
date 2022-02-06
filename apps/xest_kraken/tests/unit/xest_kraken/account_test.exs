defmodule XestKraken.Account.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias XestKraken.Account
  alias XestKraken.Auth

  import Hammox

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: XestKraken.Account, behaviour: XestKraken.Account.Behaviour

  setup do
    acc_pid =
      start_supervised!({
        Account,
        # passing nil as we rely on a mock here.
        # we will use a mock for Auth genserver
        # we use a mock: no pid.
        name: String.to_atom("#{__MODULE__}.Process"),
        auth_mod: XestKraken.Auth.Mock,
        auth_pid: nil
      })

    # setting up server mock to test the chain
    # Account -> Agent messaging -> KrakenAuthenticated
    # without relying on a specific server implementation
    Auth.Mock
    |> allow(self(), acc_pid)

    %{acc_pid: acc_pid}
  end

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "retrieve balance", %{acc_pid: acc_pid} do
    Auth.Mock
    |> expect(:balance, fn _ ->
      {:ok,
       %Account.Balance{
         balances: [
           %Account.AssetBalance{
             asset: "BTC",
             amount: "42.35"
           },
           %Account.AssetBalance{
             asset: "ETH",
             amount: "51.23"
           }
         ]
       }}
    end)

    %Xest.Account.Balance{balances: bal} = Account.balance(acc_pid)

    assert bal == [
             %Xest.Account.AssetBalance{
               asset: "BTC",
               free: "42.35",
               locked: "0.0"
             },
             %Xest.Account.AssetBalance{
               asset: "ETH",
               free: "51.23",
               locked: "0.0"
             }
           ]
  end

  test "retrieve trades", %{acc_pid: acc_pid} do
    symbol = "symbol"

    Auth.Mock
    |> expect(:trades, fn _ ->
      {:ok,
       %Account.Trades{
         trades: %{
           "some_id" => %Account.Trade{
             cost: 0.0,
             fee: 0.0,
             margin: 0.0,
             misc: "",
             ordertxid: "",
             ordertype: "",
             pair: symbol,
             postxid: "",
             price: 0.0,
             time: 0.0,
             type: "",
             vol: 0.0
           },
           "another_id" => %Account.Trade{
             cost: 0.0,
             fee: 0.0,
             margin: 0.0,
             misc: "",
             ordertxid: "",
             ordertype: "",
             pair: symbol,
             postxid: "",
             price: 0.0,
             time: 0.0,
             type: "",
             vol: 0.0
           }
         }
       }}
    end)

    %Xest.Account.TradesHistory{history: history} =
      Account.trades(acc_pid, symbol) |> IO.inspect()

    assert history == %{
             "some_id" => %Xest.Account.Trade{
               pair: symbol,
               price: 0.0,
               time: 0.0,
               vol: 0.0
             },
             "another_id" => %Xest.Account.Trade{
               pair: symbol,
               price: 0.0,
               time: 0.0,
               vol: 0.0
             }
           }
  end
end

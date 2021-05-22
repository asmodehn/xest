defmodule XestBinance.ExchangeAccount.Test do
  use ExUnit.Case, async: true

  #  alias XestBinance.Models
  alias XestBinance.MonadicExchange
  alias XestBinance.ServerBehaviourMock

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

  test "" do
    ServerBehaviourMock
    |> expect(:system_status, fn _ ->
      {:ok, %Binance.SystemStatus{}}
    end)

    exchange = MonadicExchange.new(ServerBehaviourMock, nil)
    assert %Algae.Reader{} = exchange

    assert exchange |> MonadicExchange.system_status() == %Xest.ExchangeStatus{
             status: nil,
             message: nil
           }
  end
end

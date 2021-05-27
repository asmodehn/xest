defmodule XestBinance.ExchangeAccount.Test do
  use ExUnit.Case, async: true

  alias Xest.ShadowClock

  alias XestBinance.MonadicExchange
  alias XestBinance.ServerBehaviourMock

  import Hammox

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  #  use Hammox.Protect, module: XestBinance.MonadicAccount, behaviour: XestBinance.Ports.AccountBehaviour

  @time_stop ~U[2021-02-18 08:53:32.313Z]

  setup do
    # we pass nil as server pid to use the mock in tests, or fail otherwise.
    exchange = MonadicExchange.new(ServerBehaviourMock, nil)
    assert %MonadicExchange{} = exchange

    %{exchange: exchange}
  end

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "retrieve status", %{exchange: exchange} do
    ServerBehaviourMock
    |> expect(:system_status, fn _ ->
      {:ok, %Binance.SystemStatus{}}
    end)

    assert exchange |> MonadicExchange.system_status() == %Xest.ExchangeStatus{
             status: nil,
             message: nil
           }
  end

  test "retrieve servertime OK", %{exchange: exchange} do
    ServerBehaviourMock
    |> expect(:time!, fn _ -> @time_stop end)

    clock = exchange |> MonadicExchange.servertime()
    assert %ShadowClock{} = clock
    assert ShadowClock.now(clock) == @time_stop
  end
end

ExUnit.start()

Hammox.defmock(Xest.BinanceClientBehaviourMock, for: Xest.Ports.BinanceClientBehaviour)

Application.put_env(:xest, :binance_client_adapter, Xest.BinanceClientBehaviourMock)

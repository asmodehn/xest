ExUnit.start()

Hammox.defmock(Xest.BinanceClientBehaviourMock, for: Xest.Ports.BinanceClientBehaviour)
Hammox.stub_with(Xest.BinanceClientBehaviourMock, Xest.BinanceClient.Stub)

Hammox.defmock(Xest.BinanceServerBehaviourMock, for: Xest.Ports.BinanceServerBehaviour)
Hammox.stub_with(Xest.BinanceServerBehaviourMock, Xest.BinanceServer.Stub)

Application.put_env(:xest, :binance_client_adapter, Xest.BinanceClientBehaviourMock)

Application.put_env(:xest, :binance_server, Xest.BinanceServerBehaviourMock)

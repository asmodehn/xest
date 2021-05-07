ExUnit.start()

Hammox.defmock(XestBinance.ClientBehaviourMock, for: XestBinance.Ports.ClientBehaviour)
Hammox.stub_with(XestBinance.ClientBehaviourMock, XestBinance.Client.Stub)

Hammox.defmock(XestBinance.ServerBehaviourMock, for: XestBinance.Ports.ServerBehaviour)
Hammox.stub_with(XestBinance.ServerBehaviourMock, XestBinance.Server.Stub)

Application.put_env(:xest, :binance_client_adapter, XestBinance.ClientBehaviourMock)

Application.put_env(:xest, :binance_server, XestBinance.ServerBehaviourMock)

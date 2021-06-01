ExUnit.start()

Hammox.defmock(TestServerMock, for: Xest.APIServer)

Application.put_env(:xest, :api_test_server, TestServerMock)

# Mocking connector using provided behavior
Hammox.defmock(XestKraken.Exchange.Mock, for: XestKraken.Exchange.Behaviour)

Application.put_env(:xest, :kraken_exchange, XestKraken.Exchange.Mock)

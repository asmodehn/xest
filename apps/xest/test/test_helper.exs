ExUnit.start()

# Datetime configuration for an optional mock,
# when setting local clock is required.
Hammox.defmock(Xest.DateTime.Mock, for: Xest.DateTime.Behaviour)
Hammox.stub_with(Xest.DateTime.Mock, Xest.DateTime.Stub)

Hammox.defmock(TestServerMock, for: Xest.APIServer)

Application.put_env(:xest, :api_test_server, TestServerMock)

# Mocking connector using provided behavior
Hammox.defmock(XestKraken.Exchange.Mock, for: XestKraken.Exchange.Behaviour)

Application.put_env(:xest, :kraken_exchange, XestKraken.Exchange.Mock)

# Mocking connector using provided behavior
Hammox.defmock(XestKraken.Clock.Mock, for: XestKraken.Clock.Behaviour)

Application.put_env(:xest, :kraken_clock, XestKraken.Clock.Mock)

# Mocking connector using provided behavior
Hammox.defmock(XestBinance.Exchange.Mock, for: XestBinance.Exchange.Behaviour)

Application.put_env(:xest, :binance_exchange, XestBinance.Exchange.Mock)

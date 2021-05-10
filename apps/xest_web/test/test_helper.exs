ExUnit.start()

Hammox.defmock(XestBinance.ExchangeBehaviourMock, for: XestBinance.Ports.ExchangeBehaviour)
# Hammox.stub_with(XestBinance.ExchangeBehaviourMock, XestBinance.Exchange.Stub)

Application.put_env(:xest_web, :binance_exchange, XestBinance.ExchangeBehaviourMock)

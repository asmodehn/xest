ExUnit.start()

Hammox.defmock(XestBinance.ExchangeBehaviourMock, for: XestBinance.Ports.ExchangeBehaviour)
# Hammox.stub_with(XestBinance.ExchangeBehaviourMock, XestBinance.Exchange.Stub)

Application.put_env(:xest_web, :binance_exchange, XestBinance.ExchangeBehaviourMock)

Hammox.defmock(XestBinance.AccountBehaviourMock, for: XestBinance.Ports.AccountBehaviour)
# Hammox.stub_with(XestBinance.AccountBehaviourMock, XestBinance.Account.Stub)

Application.put_env(:xest_web, :binance_account, XestBinance.AccountBehaviourMock)

Hammox.defmock(Xest.Exchange.Mock, for: Xest.Exchange.Behaviour)
Application.put_env(:xest_web, :exchange, Xest.Exchange.Mock)

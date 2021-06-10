ExUnit.start()

Hammox.defmock(XestBinance.AccountBehaviourMock, for: XestBinance.Ports.AccountBehaviour)
# Hammox.stub_with(XestBinance.AccountBehaviourMock, XestBinance.Account.Stub)

Application.put_env(:xest_web, :binance_account, XestBinance.AccountBehaviourMock)

# TODO : deprecate: this is an old design, we should point to the xest account.
Hammox.defmock(XestKraken.Auth.Mock, for: XestKraken.Auth.Behaviour)
Application.put_env(:xest, :kraken_auth, XestKraken.Auth.Mock)

Hammox.defmock(Xest.Clock.Mock, for: Xest.Clock.Behaviour)
Application.put_env(:xest_web, :clock, Xest.Clock.Mock)

Hammox.defmock(Xest.Exchange.Mock, for: Xest.Exchange.Behaviour)
Application.put_env(:xest_web, :exchange, Xest.Exchange.Mock)

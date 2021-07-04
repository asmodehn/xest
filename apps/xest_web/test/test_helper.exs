ExUnit.start()

Hammox.defmock(Xest.Clock.Mock, for: Xest.Clock.Behaviour)
Application.put_env(:xest_web, :clock, Xest.Clock.Mock)

Hammox.defmock(Xest.Exchange.Mock, for: Xest.Exchange.Behaviour)
Application.put_env(:xest_web, :exchange, Xest.Exchange.Mock)

Hammox.defmock(Xest.Account.Mock, for: Xest.Account.Behaviour)
Application.put_env(:xest_web, :account, Xest.Account.Mock)

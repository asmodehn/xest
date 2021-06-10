ExUnit.start()

# Authenticated Server mock to use server interface in tests
Hammox.defmock(XestBinance.Auth.Mock,
  for: XestBinance.Auth.Behaviour
)

Hammox.stub_with(XestBinance.Auth.Mock, XestBinance.Auth.Stub)

Application.put_env(:xest, :binance_auth, XestBinance.Auth.Mock)

# Adapter mock to use interface in tests
Hammox.defmock(XestBinance.Adapter.Mock, for: XestBinance.Adapter.Behaviour)

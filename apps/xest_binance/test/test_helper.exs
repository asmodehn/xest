ExUnit.start()

# Authenticated Server mock to use server interface in tests
Hammox.defmock(XestBinance.AuthenticatedBehaviourMock,
  for: XestBinance.Ports.AuthenticatedBehaviour
)

Hammox.stub_with(XestBinance.AuthenticatedBehaviourMock, XestBinance.Authenticated.Stub)

Application.put_env(:xest, :binance_authenticated, XestBinance.AuthenticatedBehaviourMock)

# Adapter mock to use interface in tests
Hammox.defmock(XestBinance.Adapter.Mock, for: XestBinance.Adapter.Behaviour)

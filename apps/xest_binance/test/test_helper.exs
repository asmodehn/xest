ExUnit.start()

# Client mock to use client interface in tests
# Hammox.defmock(XestBinance.ClientBehaviourMock, for: XestBinance.Ports.ClientBehaviour)
# Hammox.stub_with(XestBinance.ClientBehaviourMock, XestBinance.Client.Stub)
#
# Application.put_env(:xest, :binance_client_adapter, XestBinance.ClientBehaviourMock)

# Server mock to use server interface in tests
Hammox.defmock(XestBinance.ServerBehaviourMock, for: XestBinance.Ports.ServerBehaviour)
Hammox.stub_with(XestBinance.ServerBehaviourMock, XestBinance.Server.Stub)

Application.put_env(:xest, :binance_server, XestBinance.ServerBehaviourMock)

# Authenticated Server mock to use server interface in tests
Hammox.defmock(XestBinance.AuthenticatedBehaviourMock,
  for: XestBinance.Ports.AuthenticatedBehaviour
)

Hammox.stub_with(XestBinance.AuthenticatedBehaviourMock, XestBinance.Authenticated.Stub)

Application.put_env(:xest, :binance_authenticated, XestBinance.AuthenticatedBehaviourMock)

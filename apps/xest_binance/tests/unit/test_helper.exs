# Here we test modular behavior, in parallel (async: true).
# We make a heavy use of mocks.

# Multi process tests are allowed, if the behaviour is consistent,
# and they have to run in parallel.

ExUnit.start()

# defining Datetime.Mock module is not defined yet
if !:erlang.function_exported(Xest.DateTime.Mock, :module_info, 0) do
  # Datetime configuration for an optional mock,
  # when setting local clock is required.
  Hammox.defmock(Xest.DateTime.Mock, for: Xest.DateTime.Behaviour)
end

# Authenticated Server mock to use server interface in tests
Hammox.defmock(XestBinance.Auth.Mock,
  for: XestBinance.Auth.Behaviour
)

Hammox.stub_with(XestBinance.Auth.Mock, XestBinance.Auth.Stub)

# Adapter mock to use interface in tests
Hammox.defmock(XestBinance.Adapter.Mock.Adapter, for: XestBinance.Adapter.Behaviour)
Hammox.defmock(XestBinance.Adapter.Mock.Exchange, for: XestBinance.Adapter.Behaviour)
Hammox.defmock(XestBinance.Adapter.Mock.Clock, for: XestBinance.Adapter.Behaviour)

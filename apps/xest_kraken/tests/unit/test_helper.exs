# Here we test modular behavior, in parallel (async: true).
# We make a heavy use of mocks.

# Multi process tests are allowed, if the behaviour is consistent,
# and they have to run in parallel.

ExUnit.start()

# defining Datetime.Mock module is not defined yet
if !:erlang.function_exported(XestClock.DateTime.Mock, :module_info, 0) do
  # Datetime configuration for an optional mock,
  # when setting local clock is required.
  Hammox.defmock(XestClock.DateTime.Mock, for: XestClock.DateTime.Behaviour)
end

# Authenticated Server mock to use server interface in tests
Hammox.defmock(XestKraken.Auth.Mock,
  for: XestKraken.Auth.Behaviour
)

Hammox.stub_with(XestKraken.Auth.Mock, XestKraken.Auth.Stub)

# adapter mock to use adapter interface in tests
Hammox.defmock(XestKraken.Adapter.Mock.Adapter, for: XestKraken.Adapter.Behaviour)
Hammox.defmock(XestKraken.Adapter.Mock.Exchange, for: XestKraken.Adapter.Behaviour)
Hammox.defmock(XestKraken.Adapter.Mock.Clock, for: XestKraken.Adapter.Behaviour)

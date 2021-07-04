ExUnit.start()

# defining Datetime.Mock module is not defined yet
if !:erlang.function_exported(Xest.DateTime.Mock, :module_info, 0) do
  # Datetime configuration for an optional mock,
  # when setting local clock is required.
  Hammox.defmock(Xest.DateTime.Mock, for: Xest.DateTime.Behaviour)
end

# Authenticated Server mock to use server interface in tests
Hammox.defmock(XestKraken.Auth.Mock,
  for: XestKraken.Auth.Behaviour
)

Hammox.stub_with(XestKraken.Auth.Mock, XestKraken.Auth.Stub)

Application.put_env(:xest, :kraken_auth, XestKraken.Auth.Mock)

# adapter mock to use adapter interface in tests
Hammox.defmock(XestKraken.Adapter.Mock, for: XestKraken.Adapter.Behaviour)

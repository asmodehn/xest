ExUnit.start()

# adapter mock to use adapter interface in tests
Hammox.defmock(XestKraken.Adapter.Mock, for: XestKraken.Adapter.Behaviour)
# Hammox.stub_with(XestKraken.Adapter.Mock, XestKraken.Adapter.Stub)

ExUnit.start()

# Datetime configuration for an optional mock, when setting local clock is required.
Hammox.defmock(XestClock.DateTime.Mock, for: XestClock.DateTime.Behaviour)

# In case a stub is needed for those usecases where time is not specified in expect/2
# Hammox.stub_with(XestClock.DateTime.Mock, XestClock.DateTime.Stub)

# Note this is only for tests. No configuration change is expected to set the DateTime module.

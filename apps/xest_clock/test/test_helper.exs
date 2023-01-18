ExUnit.start()

## Reminder: Stubs do not work when setup from here.

# System configuration for an optional mock, when setting local time is required.
Hammox.defmock(XestClock.System.OriginalMock, for: XestClock.System.OriginalBehaviour)

Application.put_env(:xest_clock, :system_module, XestClock.System.OriginalMock)

# Note this is only for tests.
# No configuration change on the user side is expected to set the System module.

# Datetime configuration for an optional mock, when setting local clock is required.
Hammox.defmock(XestClock.NewWrapper.DateTime.OriginalMock,
  for: XestClock.NewWrapper.DateTime.OriginalBehaviour
)

Application.put_env(:xest_clock, :datetime_module, XestClock.NewWrapper.DateTime.OriginalMock)

# Note this is only for tests.
# No configuration change on th user side is expected to set the DateTime module.

defmodule XestClock.ExampleClockServer.Test do
  # TMP to prevent errors given the stateful gen_server
  use ExUnit.Case, async: true
  doctest XestClock.Server.Local

  import Hammox
  use Hammox.Protect, module: XestClock.System, behaviour: XestClock.System.OriginalBehaviour

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  alias XestClock.Server.Local

  describe "ExampleTemplateUse" do
    setup do
      # We use start_supervised! from ExUnit to manage gen_stage
      # and not with the gen_stage :link option
      local_pid = start_supervised!({Local, :millisecond})
      %{local_pid: local_pid}
    end

    test "return proper Timestamp on tick()", %{local_pid: local_pid} do
      # we mock the original monotonic_time (which is used by local clock server without offset)
      XestClock.System.OriginalMock
      |> allow(self(), local_pid)
      |> expect(:monotonic_time, fn
        :second -> 42
        :millisecond -> 42_000
        :microsecond -> 42_000_000
        :nanosecond -> 42_000_000_000
        # per second
        60 -> 42 * 60
      end)
      |> expect(:time_offset, 1, fn
        _ -> 0
      end)

      assert Local.ticks(local_pid, 1) == [
               %XestClock.Timestamp{
                 origin: Local,
                 ts: 42_000,
                 unit: :millisecond
               }
             ]
    end
  end
end

defmodule XestClock.ExampleTemplateUse.Test do
  # TMP to prevent errors given the stateful gen_server
  use ExUnit.Case, async: false
  doctest XestClock.ExampleClockServer

  alias XestClock.ExampleClockServer

  describe "ExampleTemplateUse" do
    setup do
      # We use start_supervised! from ExUnit to manage gen_stage
      # and not with the gen_stage :link option
      example_template_pid = start_supervised!({ExampleClockServer, {:some_remote, :millisecond}})
      %{example_template_pid: example_template_pid}
    end

    test "return proper Timestamp on tick()", %{example_template_pid: example_template_pid} do
      assert ExampleClockServer.tick(example_template_pid) == %XestClock.Timestamp{
               origin: :some_remote,
               ts: 42,
               unit: :millisecond
             }
    end
  end
end

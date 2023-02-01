defmodule XestClock.ServerTest do
  # TMP to prevent errors given the stateful gen_server
  use ExUnit.Case, async: false
  doctest XestClock.Server

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  require ExampleServer

  describe "XestClock.Server" do
    #    setup %{unit: unit} do
    #        # mocks expectations are needed since clock also tracks local time internally
    #        XestClock.System.ExtraMock
    #        |> expect(:native_time_unit, fn -> unit  end)
    #
    #      # We use start_supervised! from ExUnit to manage gen_stage
    #      # and not with the gen_stage :link option
    #      example_srv = start_supervised!({ExampleServer, unit})
    #      %{example_srv: example_srv}
    #    end

    #    @tag unit: :second
    #    @tag unit: :millisecond
    test "tick depends on unit on creation, it reached all the way to the callback" do
      example_srv = start_supervised!({ExampleServer, :second}, id: :example_sec)

      assert ExampleServer.tick(example_srv) == {
               %XestClock.Time.Stamp{
                 origin: ExampleServer,
                 ts: %XestClock.Time.Value{
                   value: 42,
                   offset: nil,
                   unit: :second
                 }
               },
               %XestClock.Stream.Timed.LocalStamp{
                 monotonic: %XestClock.Time.Value{
                   value: 42,
                   offset: nil,
                   unit: :nanosecond
                 },
                 unit: :nanosecond,
                 vm_offset: 0
               },
               %XestClock.Stream.Timed.LocalDelta{
                 offset: %XestClock.Time.Value{
                   offset: nil,
                   unit: :second,
                   value: 42
                 },
                 skew: nil
               }
             }

      #               %XestClock.Timestamp{
      #               origin: XestClock.ServerTest.ExampleServer,
      #               ts: %XestClock.TimeValue{monotonic: 42, offset: nil, skew: nil, unit: :second}
      #             }

      stop_supervised!(:example_sec)

      example_srv = start_supervised!({ExampleServer, :millisecond}, id: :example_millisec)

      assert ExampleServer.tick(example_srv) == {
               %XestClock.Time.Stamp{
                 origin: ExampleServer,
                 ts: %XestClock.Time.Value{
                   value: 42_000,
                   offset: nil,
                   unit: :millisecond
                 }
               },
               %XestClock.Stream.Timed.LocalStamp{
                 monotonic: %XestClock.Time.Value{
                   value: 42,
                   offset: nil,
                   unit: :nanosecond
                 },
                 unit: :nanosecond,
                 vm_offset: 0
               },
               %XestClock.Stream.Timed.LocalDelta{
                 offset: %XestClock.Time.Value{
                   offset: nil,
                   unit: :millisecond,
                   value: 42000
                 },
                 skew: nil
               }
             }

      stop_supervised!(:example_millisec)

      example_srv = start_supervised!({ExampleServer, :microsecond}, id: :example_microsec)

      assert ExampleServer.tick(example_srv) == {
               %XestClock.Time.Stamp{
                 origin: ExampleServer,
                 ts: %XestClock.Time.Value{
                   value: 42_000_000,
                   offset: nil,
                   unit: :microsecond
                 }
               },
               %XestClock.Stream.Timed.LocalStamp{
                 monotonic: %XestClock.Time.Value{
                   value: 42,
                   offset: nil,
                   unit: :nanosecond
                 },
                 unit: :nanosecond,
                 vm_offset: 0
               },
               %XestClock.Stream.Timed.LocalDelta{
                 offset: %XestClock.Time.Value{
                   offset: nil,
                   unit: :microsecond,
                   value: 42_000_000
                 },
                 skew: nil
               }
             }

      #               %XestClock.Timestamp{
      #               origin: XestClock.ServerTest.ExampleServer,
      #               ts: %XestClock.TimeValue{
      #                 monotonic: 42_000_000,
      #                 offset: nil,
      #                 skew: nil,
      #                 unit: :microsecond
      #               }
      #             }

      stop_supervised!(:example_microsec)

      example_srv = start_supervised!({ExampleServer, :nanosecond}, id: :example_nanosec)

      assert ExampleServer.tick(example_srv) == {
               %XestClock.Time.Stamp{
                 origin: ExampleServer,
                 ts: %XestClock.Time.Value{
                   value: 42_000_000_000,
                   offset: nil,
                   unit: :nanosecond
                 }
               },
               %XestClock.Stream.Timed.LocalStamp{
                 monotonic: %XestClock.Time.Value{
                   value: 42,
                   offset: nil,
                   unit: :nanosecond
                 },
                 unit: :nanosecond,
                 vm_offset: 0
               },
               %XestClock.Stream.Timed.LocalDelta{
                 offset: %XestClock.Time.Value{
                   offset: nil,
                   unit: :nanosecond,
                   value: 41_999_999_958
                 },
                 skew: nil
               }
             }

      #               %XestClock.Timestamp{
      #               origin: XestClock.ServerTest.ExampleServer,
      #               ts: %XestClock.TimeValue{
      #                 monotonic: 42_000_000_000,
      #                 offset: nil,
      #                 skew: nil,
      #                 unit: :nanosecond
      #               }
      #             }

      stop_supervised!(:example_nanosec)
    end
  end
end

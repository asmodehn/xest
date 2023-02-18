defmodule XestClock.ServerTest do
  # TMP to prevent errors given the stateful gen_server
  use ExUnit.Case, async: false
  doctest XestClock.Server

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  require ExampleServer

  describe "tick" do
    test "provides value, local timestamp and delta with correct unit" do
      # mocks expectations are needed since clock also tracks local time internally
      #      XestClock.System.ExtraMock
      #      |> expect(:native_time_unit, 4, fn -> :nanosecond end)
      # |> allow(self(), example_srv)

      srv_id = String.to_atom("example_tick")

      example_srv =
        start_supervised!(
          {ExampleServer,
           fn ->
             XestClock.Time.Value.new(
               :second,
               XestClock.System.monotonic_time(:second)
             )
           end},
          id: srv_id
        )

      # Preparing mocks for 2 calls for first tick...
      # This is used for local stamp -> only in ms
      XestClock.System.OriginalMock
      |> expect(:monotonic_time, 3, fn
        # second to simulate the remote clock, required by the example genserver
        # TODO : make this a mock ? need a stable behaviour for the server...
        :second -> 42
        # nano second for the precision internal to the proxy server (and its internal stream)
        :nanosecond -> 42_000_000_000
      end)
      |> expect(:time_offset, 2, fn _ -> 0 end)
      |> allow(self(), example_srv)

      assert ExampleServer.tick(example_srv) == {
               %XestClock.Time.Value{
                 value: 42,
                 unit: :second
               },
               # Local stamp is always in millisecond (sleep pecision)
               %XestClock.Stream.Timed.LocalStamp{
                 monotonic: 42_000_000_000,
                 unit: :nanosecond,
                 vm_offset: 0
               },
               %XestClock.Stream.Timed.LocalDelta{
                 offset: %XestClock.Time.Value{
                   unit: :nanosecond,
                   value: 0
                 },
                 skew: nil
               }
             }

      XestClock.Process.OriginalMock
      # Note : since this test code will tick faster than the unit in this case,
      # we need to mock sleep.
      |> expect(:sleep, 1, fn _ -> :ok end)
      |> allow(self(), example_srv)

      # Preparing mocks for 3 (because sleep) more calls for next tick...
      # This is used for local stamp -> only in ms
      XestClock.System.OriginalMock
      |> expect(:monotonic_time, 4, fn
        # second to simulate the remote clock, required by the example genserver
        # TODO : make this a mock ? need a stable behaviour for the server...
        :second -> 42
        # nano second for the precision internal to the proxy server (and its internal stream)
        :nanosecond -> 42_000_000_000
        # default and parts per seconds
        pps -> 42 * pps
      end)
      |> expect(:time_offset, 3, fn _ -> 0 end)
      |> allow(self(), example_srv)

      # second tick
      assert ExampleServer.tick(example_srv) == {
               %XestClock.Time.Value{
                 value: 42,
                 unit: :second
               },
               # Local stamp is always in millisecond (sleep pecision)
               %XestClock.Stream.Timed.LocalStamp{
                 monotonic: 42_000_000_000,
                 unit: :nanosecond,
                 vm_offset: 0
               },
               %XestClock.Stream.Timed.LocalDelta{
                 offset: %XestClock.Time.Value{
                   unit: :nanosecond,
                   value: 0
                 },
                 # offset 0 : skew is nil (like the previous one, since it is not computable without time moving forward)
                 skew: nil
               }
             }

      stop_supervised!(srv_id)
    end
  end

  describe "compute_offset" do
    # TODO
  end

  describe "monotonic_time" do
    test "returns a local estimation of the remote clock" do
      srv_id = String.to_atom("example_monotonic")

      example_srv =
        start_supervised!(
          {ExampleServer,
           fn ->
             XestClock.Time.Value.new(
               :second,
               XestClock.System.monotonic_time(:second)
             )
           end},
          id: srv_id
        )

      # Preparing mocks for 2 + 1 + 1 ticks...
      # This is used for local stamp -> only in ms
      XestClock.System.OriginalMock
      |> expect(:monotonic_time, 5, fn
        # second to simulate the remote clock, required by the example genserver
        # TODO : make this a mock ? need a stable behaviour for the server...
        :second -> 42
        # millisecond for the precision required locally on the client (test genserver)
        :millisecond -> 51_000
        # nano second for the precision internal to the proxy server (and its internal stream)
        :nanosecond -> 51_000_000_000
      end)
      |> expect(:time_offset, 4, fn _ -> 0 end)
      |> allow(self(), example_srv)

      # getting monotonic_time of the server gives us the value received from the remote clock
      assert ExampleServer.monotonic_time(example_srv, :millisecond) == 42_000
    end
  end

  describe "monotonic_time_value" do
    test "on first tick returns offset without error" do
      srv_id = String.to_atom("example_error_nil")

      example_srv =
        start_supervised!(
          {ExampleServer,
           fn ->
             XestClock.Time.Value.new(
               :second,
               XestClock.System.monotonic_time(:second)
             )
           end},
          id: srv_id
        )

      # Preparing mocks for only 1 measurement ticks...
      # This is used for local stamp -> only in ms
      # Then expect 2 more ticks for the first monotonic time request.
      # plus one more to estimate offset error
      # => total of 4 ticks
      XestClock.System.OriginalMock
      |> expect(:monotonic_time, 5, fn
        # second to simulate the remote clock, required by the example genserver
        # TODO : make this a mock ? need a stable behaviour for the server...
        :second -> 42
        # millisecond for the precision required locally on the client (test genserver)
        :millisecond -> 51_000
        # nano second for the precision internal to the proxy server (and its internal stream)
        :nanosecond -> 51_000_000_000
      end)
      |> expect(:time_offset, 4, fn _ -> 0 end)
      |> allow(self(), example_srv)

      # getting monotonic_time of the server gives us the value received from the remote clock
      assert XestClock.Server.monotonic_time_value(example_srv, :millisecond) ==
               %XestClock.Time.Value{unit: :millisecond, value: 42000, error: 0}
    end
  end

  describe "start_link" do
    # TODO
  end
end

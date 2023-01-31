defmodule XestClock.ServerTest do
  # TMP to prevent errors given the stateful gen_server
  use ExUnit.Case, async: false
  doctest XestClock.Server

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  defmodule ExampleServer do
    use XestClock.Server
    # use will setup the correct streamclock for leveraging the `handle_remote_unix_time` callback
    # the unit passed as parameter will be sent to handle_remote_unix_time

    # Client code

    # already defined in macro. good or not ?
    @impl true
    def start_link(unit, opts \\ []) when is_list(opts) do
      XestClock.Server.start_link(__MODULE__, unit, opts)
    end

    @impl true
    def init(state) do
      # mocks expectations are needed since clock also tracks local time internally
      XestClock.System.ExtraMock
      |> expect(:native_time_unit, fn -> :nanosecond end)

      XestClock.System.OriginalMock
      # TODO: This should fail on exit: it is called only once !
      |> expect(:monotonic_time, 25, fn _ -> 42 end)
      |> expect(:time_offset, fn _ -> 0 end)

      # Note : the local timestamp calls these one time only.
      # other stream operator will rely on that timestamp

      XestClock.Process.OriginalMock
      # Note : since we tick faster than unit here, we need to mock sleep.
      |> expect(:sleep, 1, fn _ -> :ok end)

      # This is not of interest in tests, which is why it is quickly done here internally.
      # Otherwise see allowances to do it from another process:
      # https://hexdocs.pm/mox/Mox.html#module-explicit-allowances

      # TODO : verify mocks are not called too often !
      #      verify_on_exit!()  # this wants to be called from the test process...

      XestClock.Server.init(state, &handle_remote_unix_time/1)
    end

    def tick(pid \\ __MODULE__) do
      List.first(ticks(pid, 1))
    end

    @impl true
    def ticks(pid \\ __MODULE__, demand) do
      XestClock.Server.ticks(pid, demand)
    end

    ## Callbacks
    @impl true
    def handle_remote_unix_time(unit) do
      case unit do
        :second -> 42
        :millisecond -> 42_000
        :microsecond -> 42_000_000
        :nanosecond -> 42_000_000_000
        # default and parts per seconds
        pps -> 42 * pps
      end
    end
  end

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

    @tag unit: :second
    @tag unit: :millisecond
    test "tick depends on unit on creation, it reached all the way to the callback" do
      example_srv = start_supervised!({ExampleServer, :second}, id: :example_sec)

      assert ExampleServer.tick(example_srv) == {
               %XestClock.Timestamp{
                 origin: XestClock.ServerTest.ExampleServer,
                 ts: %XestClock.TimeValue{
                   monotonic: 42,
                   offset: nil,
                   skew: nil,
                   unit: :second
                 }
               },
               %XestClock.Stream.Timed.LocalStamp{
                 monotonic: %XestClock.TimeValue{
                   monotonic: 42,
                   offset: nil,
                   skew: nil,
                   unit: :nanosecond
                 },
                 unit: :nanosecond,
                 vm_offset: 0
               }
             }

      #               %XestClock.Timestamp{
      #               origin: XestClock.ServerTest.ExampleServer,
      #               ts: %XestClock.TimeValue{monotonic: 42, offset: nil, skew: nil, unit: :second}
      #             }

      stop_supervised!(:example_sec)

      example_srv = start_supervised!({ExampleServer, :millisecond}, id: :example_millisec)

      assert ExampleServer.tick(example_srv) == {
               %XestClock.Timestamp{
                 origin: XestClock.ServerTest.ExampleServer,
                 ts: %XestClock.TimeValue{
                   monotonic: 42_000,
                   offset: nil,
                   skew: nil,
                   unit: :millisecond
                 }
               },
               %XestClock.Stream.Timed.LocalStamp{
                 monotonic: %XestClock.TimeValue{
                   monotonic: 42,
                   offset: nil,
                   skew: nil,
                   unit: :nanosecond
                 },
                 unit: :nanosecond,
                 vm_offset: 0
               }
             }

      stop_supervised!(:example_millisec)

      example_srv = start_supervised!({ExampleServer, :microsecond}, id: :example_microsec)

      assert ExampleServer.tick(example_srv) == {
               %XestClock.Timestamp{
                 origin: XestClock.ServerTest.ExampleServer,
                 ts: %XestClock.TimeValue{
                   monotonic: 42_000_000,
                   offset: nil,
                   skew: nil,
                   unit: :microsecond
                 }
               },
               %XestClock.Stream.Timed.LocalStamp{
                 monotonic: %XestClock.TimeValue{
                   monotonic: 42,
                   offset: nil,
                   skew: nil,
                   unit: :nanosecond
                 },
                 unit: :nanosecond,
                 vm_offset: 0
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
               %XestClock.Timestamp{
                 origin: XestClock.ServerTest.ExampleServer,
                 ts: %XestClock.TimeValue{
                   monotonic: 42_000_000_000,
                   offset: nil,
                   skew: nil,
                   unit: :nanosecond
                 }
               },
               %XestClock.Stream.Timed.LocalStamp{
                 monotonic: %XestClock.TimeValue{
                   monotonic: 42,
                   offset: nil,
                   skew: nil,
                   unit: :nanosecond
                 },
                 unit: :nanosecond,
                 vm_offset: 0
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

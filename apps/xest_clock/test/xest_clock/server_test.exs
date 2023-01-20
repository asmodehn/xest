defmodule XestClock.ServerTest do
  # TMP to prevent errors given the stateful gen_server
  use ExUnit.Case, async: false
  doctest XestClock.Server

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
    setup %{unit: unit} do
      # We use start_supervised! from ExUnit to manage gen_stage
      # and not with the gen_stage :link option
      example_srv = start_supervised!({ExampleServer, unit})
      %{example_srv: example_srv}
    end

    @tag unit: :second
    @tag unit: :millisecond
    test "tick depends on unit on creation, it reached all the way to the callback" do
      example_srv = start_supervised!({ExampleServer, :second}, id: :example_sec)

      assert ExampleServer.tick(example_srv) == %XestClock.Timestamp{
               origin: XestClock.ServerTest.ExampleServer,
               ts: 42,
               unit: :second
             }

      stop_supervised!(:example_sec)

      example_srv = start_supervised!({ExampleServer, :millisecond}, id: :example_millisec)

      assert ExampleServer.tick(example_srv) == %XestClock.Timestamp{
               origin: XestClock.ServerTest.ExampleServer,
               ts: 42_000,
               unit: :millisecond
             }

      stop_supervised!(:example_millisec)

      example_srv = start_supervised!({ExampleServer, :microsecond}, id: :example_microsec)

      assert ExampleServer.tick(example_srv) == %XestClock.Timestamp{
               origin: XestClock.ServerTest.ExampleServer,
               ts: 42_000_000,
               unit: :microsecond
             }

      stop_supervised!(:example_microsec)

      example_srv = start_supervised!({ExampleServer, :nanosecond}, id: :example_nanosec)

      assert ExampleServer.tick(example_srv) == %XestClock.Timestamp{
               origin: XestClock.ServerTest.ExampleServer,
               ts: 42_000_000_000,
               unit: :nanosecond
             }

      stop_supervised!(:example_nanosec)
    end
  end
end

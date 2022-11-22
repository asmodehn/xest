defmodule XestClock.Event.Local.Test do
  use ExUnit.Case
  doctest XestClock.Event.Local

  alias XestClock.Event

  describe "Event" do
    test "new/2 allows passing a custom event structure and a timestamp" do
      expected = %Event.Local{
        # Note : event work with integers
        at: XestClock.Clock.Timestamp.new(:test_local, :millisecond, 34_545_645_423),
        data: %{something: :happened}
      }

      testing = Event.Local.new(expected.data, expected.at)
      assert expected.data == testing.data
      assert expected.at == testing.at
    end

    setup do
      #  A simple test ticker agent, that ticks everytime it is called
      # TODO : use start_supervised
      {:ok, clock_agent} =
        Agent.start_link(fn ->
          # The ticks as a sequence
          [1, 2_000, 3_000_000, 4_000_000_000, 42]
          # Note : for stream we need one more than retrieved...
        end)

      # TODO : use start_supervised
      {:ok, event_agent} =
        Agent.start_link(fn ->
          # The event as a sequence
          [:first, :second, :third, :fourth, :fifth]
          # Note : for stream we need one more than retrieved...
        end)

      # a function returning a closure traversing the agent state as a list
      cursor = fn agent_pid ->
        fn ->
          Agent.get_and_update(
            agent_pid,
            fn [h | t] -> {h, t} end
          )
        end
      end

      %{ticker: cursor.(clock_agent), source: cursor.(event_agent)}
    end

    test "stream returns a stream", %{ticker: ticker, source: source} do
      clock = XestClock.Clock.new(:local_testclock, :nanosecond, ticker)

      assert Event.Local.stream(source, clock)
             |> Stream.take(4)
             |> Enum.to_list() == [
               %Event.Local{
                 at: %XestClock.Clock.Timestamp{
                   origin: :local_testclock,
                   ts: 1,
                   unit: :nanosecond
                 },
                 data: :first
               },
               %Event.Local{
                 at: %XestClock.Clock.Timestamp{
                   origin: :local_testclock,
                   ts: 2_000,
                   unit: :nanosecond
                 },
                 data: :second
               },
               %Event.Local{
                 at: %XestClock.Clock.Timestamp{
                   origin: :local_testclock,
                   ts: 3_000_000,
                   unit: :nanosecond
                 },
                 data: :third
               },
               %Event.Local{
                 at: %XestClock.Clock.Timestamp{
                   origin: :local_testclock,
                   ts: 4_000_000_000,
                   unit: :nanosecond
                 },
                 data: :fourth
               }
             ]
    end
  end
end

defmodule XestClock.Event.Remote.Test do
  use ExUnit.Case
  doctest XestClock.Event.Remote

  alias XestClock.Clock
  alias XestClock.Event

  describe "Event.Remote" do
    setup do
      ti =
        Clock.Timeinterval.build(
          Clock.Timestamp.new(:local, :millisecond, 123),
          Clock.Timestamp.new(:local, :millisecond, 456)
        )

      %{interval: ti}
    end

    test "new/3 allows local timestamp",
         %{interval: ti} do
      evt = Event.Remote.new(:my_event_data, ti)

      assert evt == %Event.Remote{
               inside: ti,
               data: :my_event_data
             }
    end

    test "new/3 forbids non-local timeinterval" do
      rti =
        Clock.Timeinterval.build(
          Clock.Timestamp.new(:somewhere, :millisecond, 123),
          Clock.Timestamp.new(:somewhere, :millisecond, 456)
        )

      assert_raise(ArgumentError, fn -> Event.Remote.new(:my_event_data, rti) end)
    end

    setup do
      #  A simple test ticker agent, that ticks everytime it is called
      # TODO : use start_supervised
      {:ok, clock_agent} =
        Agent.start_link(fn ->
          # The ticks as a sequence
          # Note : here we need duplicated ticks for before and after the task
          # Note : we also dont need the last *extra one*... since it is included in the Task run
          [1, 2, 2_000, 2_500, 3_000_000, 3_500_000, 4_000_000_000, 4_500_000_000]
        end)

      # TODO : use start_supervised
      {:ok, event_agent} =
        Agent.start_link(fn ->
          # The event as a sequence
          # Note : we dont need the last *extra one* (compared ot the sync case)...
          # since it is included in the Task run (and not run by the stream)
          [:first, :second, :third, :fourth]
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
      # Note :  wepass :local to bypass the check preventing any other clock in remtoe event...
      # TODO :  is this really necessary ??? or useful ??? what are actual usecases ?
      clock = XestClock.Clock.new(:local, :nanosecond, ticker)

      assert XestClock.Event.Remote.stream(source, clock)
             |> Stream.take(4)
             |> Enum.to_list() == [
               %XestClock.Event.Remote{
                 data: :first,
                 inside: %XestClock.Clock.Timeinterval{
                   interval: %Interval.Integer{left: {:inclusive, 1}, right: {:exclusive, 2}},
                   origin: :local,
                   unit: :nanosecond
                 }
               },
               %XestClock.Event.Remote{
                 data: :second,
                 inside: %XestClock.Clock.Timeinterval{
                   interval: %Interval.Integer{
                     left: {:inclusive, 2000},
                     right: {:exclusive, 2500}
                   },
                   origin: :local,
                   unit: :nanosecond
                 }
               },
               %XestClock.Event.Remote{
                 data: :third,
                 inside: %XestClock.Clock.Timeinterval{
                   interval: %Interval.Integer{
                     left: {:inclusive, 3_000_000},
                     right: {:exclusive, 3_500_000}
                   },
                   origin: :local,
                   unit: :nanosecond
                 }
               },
               %XestClock.Event.Remote{
                 data: :fourth,
                 inside: %XestClock.Clock.Timeinterval{
                   interval: %Interval.Integer{
                     left: {:inclusive, 4_000_000_000},
                     right: {:exclusive, 4_500_000_000}
                   },
                   origin: :local,
                   unit: :nanosecond
                 }
               }
             ]
    end
  end
end

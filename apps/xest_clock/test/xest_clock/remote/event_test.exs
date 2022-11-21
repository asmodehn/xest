defmodule XestClock.Remote.Event.Test do
  use ExUnit.Case
  doctest XestClock.Remote.Event

  alias XestClock.Clock.Timestamps
  alias XestClock.Remote.Event

  describe "Clock.Timestamps" do
    test "new/3 allows local timestamp" do
      ts = Timestamps.new(:local, :millisecond, [123, 456, 789])
      evt = Event.new(:my_event_data, ts)

      assert evt == %Event{
               before: ts,
               data: :my_event_data
             }
    end

    test "new/3 forbids non-local timestamp" do
      ts = Timestamps.new(:test_origin, :millisecond, [123, 456, 789])
      assert_raise(ArgumentError, fn -> Event.new(:my_event_data, ts) end)
    end
  end
end

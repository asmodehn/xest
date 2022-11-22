defmodule XestClock.Remote.Event.Test do
  use ExUnit.Case
  doctest XestClock.Remote.Event

  alias XestClock.Clock
  alias XestClock.Remote.Event

  describe "Remote.Event" do
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
      evt = Event.new(:my_event_data, ti)

      assert evt == %Event{
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

      assert_raise(ArgumentError, fn -> Event.new(:my_event_data, rti) end)
    end
  end
end

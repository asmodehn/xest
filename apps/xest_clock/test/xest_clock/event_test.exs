defmodule XestClock.Event.Test do
  use ExUnit.Case
  doctest XestClock.Event

  alias XestClock.Event
  alias XestClock.Clock

  describe "Event" do
    test "local/2 allows passing a custom event structure and a (local) timestamp" do
      expected = %Event.Local{
        # Note : event work with integers
        at: Clock.Timestamp.new(:test_local, :millisecond, 34_545_645_423),
        data: %{something: :happened}
      }

      testing = Event.local(expected.data, expected.at)
      assert expected.data == testing.data
      assert expected.at == testing.at
    end

    test "remote/2 allows passing a custom event structure and a (local) timeinterval" do
      expected = %Event.Remote{
        # Note : event work with integers
        inside:
          Clock.Timeinterval.build(
            Clock.Timestamp.new(:local, :millisecond, 34_545_645_423),
            Clock.Timestamp.new(:local, :millisecond, 34_545_645_507)
          ),
        data: %{something: :happened}
        # Note: we pass :local as origin to fool the detection of any other time origin.
        # TODO : is this really valid ??? maybe there are usecases wher we want actual remote clocks ??
        #    but maybe not intervals ???
      }

      testing = Event.remote(expected.data, expected.inside)
      assert expected.data == testing.data
      assert expected.inside == testing.inside
    end
  end
end

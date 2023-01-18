defmodule XestClock.StreamClockTest do
  use ExUnit.Case
  doctest XestClock.StreamClock

  alias XestClock.StreamClock
  alias XestClock.Timestamp

  @doc """
  util function to always pattern match on timestamps
  """
  def ts_retrieve(ticks, origin, unit) do
    for t <- ticks do
      %Timestamp{
        origin: ^origin,
        ts: ts,
        unit: ^unit
      } = t

      ts
    end
  end

  describe "XestClock.Clock" do
    test "stream/2 refuses :native or unknown time units" do
      assert_raise(ArgumentError, fn ->
        XestClock.StreamClock.new(:local, :native)
      end)

      assert_raise(ArgumentError, fn ->
        XestClock.StreamClock.new(:local, :unknown_time_unit)
      end)
    end

    test "stream/2 pipes increasing timestamp for local clock" do
      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
        clock = XestClock.StreamClock.new(:local, unit)

        tick_list = clock |> Enum.take(2) |> Enum.to_list()

        assert Enum.sort(tick_list, :asc) == tick_list
      end
    end

    test "stream/3 stops at the first integer that is not greater than the current one" do
      clock = XestClock.StreamClock.new(:testclock, :second, [1, 2, 3, 5, 4])

      assert clock |> Enum.to_list() |> ts_retrieve(:testclock, :second) == [
               1,
               2,
               3,
               5,
               5
             ]
    end

    test "stream/3 returns increasing timestamp for clock using agent update as read function" do
      #  A simple test ticker agent, that ticks everytime it is called
      {:ok, clock_agent} =
        start_supervised(
          {Agent,
           fn ->
             [1, 2, 3, 5, 4]
           end}
        )

      ticker = fn ->
        Agent.get_and_update(
          clock_agent,
          fn
            # this is needed only if stream wants more elements than expected (infinitely ?)
            #            [] -> {nil, []}
            [h | t] -> {h, t}
          end
        )
      end

      # NB : using an agent to store state is NOT similar to Stream.unfold(),
      # As all operations on a stream have to be done "at once",
      # and cannot "tick by tick", as possible when an agent stores the state.

      # The agent usecase is similar to what happens with the system clock, or with a remote clock.

      # However we *can encapsulate/abstract* the Agent (state-updating) request behaviour
      # with a stream repeatedly calling and updating the agent (as with the system clock)

      clock =
        XestClock.StreamClock.new(
          :testclock,
          :nanosecond,
          Stream.repeatedly(fn -> ticker.() end)
        )

      # Note : we can take/2 only 4 elements (because of monotonicity constraint).
      # Attempting to take more will keep calling the ticker
      # and fail since the [] -> {nil, []} line is commented
      # TODO : taking more should stop the agent, and end the stream...
      assert clock |> Stream.take(4) |> Enum.to_list() |> ts_retrieve(:testclock, :nanosecond) ==
               [
                 1,
                 2,
                 3,
                 5
               ]
    end

    test "as_timestamp/1 transform the clock stream into a stream of monotonous timestamps." do
      clock = XestClock.StreamClock.new(:testclock, :second, [1, 2, 3, 5, 4])

      assert clock |> Enum.to_list() |> ts_retrieve(:testclock, :second) ==
               [
                 1,
                 2,
                 3,
                 5,
                 5
               ]
    end

    test "convert/2 convert from one unit to another" do
      clock = XestClock.StreamClock.new(:testclock, :second, [1, 2, 3, 5, 4])

      assert XestClock.StreamClock.convert(clock, :millisecond)
             |> Enum.to_list()
             |> ts_retrieve(:testclock, :millisecond) == [
               1000,
               2000,
               3000,
               5000,
               5000
             ]
    end

    test "offset/2 computes difference between clocks" do
      clock_a = XestClock.StreamClock.new(:testclock_a, :second, [1, 2, 3, 5, 4])
      clock_b = XestClock.StreamClock.new(:testclock_b, :second, [11, 12, 13, 15, 124])

      assert clock_a |> XestClock.StreamClock.offset(clock_b) ==
               %XestClock.Timestamp{origin: :testclock_b, ts: 10, unit: :second}
    end

    test "offset/2 of same clock is null" do
      clock_a = XestClock.StreamClock.new(:testclock_a, :second, [1, 2, 3])
      clock_b = XestClock.StreamClock.new(:testclock_b, :second, [1, 2, 3])

      assert clock_a |> XestClock.StreamClock.offset(clock_b) ==
               %XestClock.Timestamp{origin: :testclock_b, ts: 0, unit: :second}
    end
  end

  describe "Xestclock.StreamClock with offset" do
    setup do
      clock_seq = [1, 2, 3, 4, 5]
      ref_seq = [0, 2, 4, 6, 8]

      # for loop to test various clock offset by dropping first ticks
      expected_offsets = [1, 0, -1, -2, -3]

      %{
        clock: clock_seq,
        ref: ref_seq,
        expect: expected_offsets
      }
    end

    test "new/3 does return clock with offset of zero", %{
      ref: ref_seq
    } do
      ref = StreamClock.new(:refclock, :second, ref_seq)

      assert %{ref | stream: ref.stream |> Enum.to_list()} == %StreamClock{
               origin: :refclock,
               unit: :second,
               stream: ref_seq,
               offset: %Timestamp{
                 origin: :refclock,
                 unit: :second,
                 ts: 0
               }
             }
    end

    test "add_offset/2 adds the offset passed as parameter", %{
      clock: clock_seq,
      ref: ref_seq,
      expect: expected_offsets
    } do
      for i <- 0..4 do
        clock = StreamClock.new(:testremote, :second, clock_seq |> Enum.drop(i))
        ref = StreamClock.new(:refclock, :second, ref_seq |> Enum.drop(i))

        offset =
          StreamClock.offset(
            ref,
            clock
          )

        proxy =
          StreamClock.new(:refclock, :second, ref_seq |> Enum.drop(i))
          |> StreamClock.add_offset(offset)

        # Enum. to_list() is used to compute the whole stream at once
        assert %{proxy | stream: proxy.stream |> Enum.to_list()} == %StreamClock{
                 origin: :refclock,
                 unit: :second,
                 stream: ref_seq |> Enum.drop(i),
                 offset: %Timestamp{
                   origin: :testremote,
                   unit: :second,
                   # this is only computed with one check of each clock
                   ts: expected_offsets |> Enum.at(i)
                 }
               }
      end
    end

    test "add_offset/2 computes the time offset but for a proxy clock", %{
      clock: clock_seq,
      ref: ref_seq,
      expect: expected_offsets
    } do
      for i <- 0..4 do
        clock = StreamClock.new(:testremote, :second, clock_seq |> Enum.drop(i))
        ref = StreamClock.new(:refclock, :second, ref_seq |> Enum.drop(i))

        proxy = ref |> StreamClock.follow(clock)

        assert proxy
               # here we check one by one
               |> StreamClock.to_datetime(fn :second -> 42 end)
               |> Enum.at(0) ==
                 DateTime.from_unix!(
                   Enum.at(ref_seq, i) + 42 + Enum.at(expected_offsets, i),
                   :second
                 )
      end
    end

    @tag skip: true
    test "to_datetime/2 computes the current datetime for a clock", %{
      clock: clock_seq,
      ref: ref_seq,
      expect: expected_offsets
    } do
      # CAREFUL: we need to adjust the offset, as well as the next clock tick in the sequence
      # in order to get the simulated current datetime of the proxy
      expected_dt =
        expected_offsets
        |> Enum.zip(ref_seq |> Enum.drop(1))
        |> Enum.map(fn {offset, ref} ->
          DateTime.from_unix!(42 + offset + ref, :second)
        end)

      # TODO : fix implementation... test seems okay ??
      for i <- 0..4 do
        clock = StreamClock.new(:testremote, :second, clock_seq |> Enum.drop(i))
        ref = StreamClock.new(:refclock, :second, ref_seq |> Enum.drop(i))

        proxy = ref |> StreamClock.follow(clock)

        assert proxy
               |> StreamClock.to_datetime(fn :second -> 42 end)
               |> Enum.to_list() == expected_dt
      end
    end
  end

  # TODO : add test of streamclock inside a Server (see stream.ticker test comments)
end

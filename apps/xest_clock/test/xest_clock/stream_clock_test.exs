defmodule XestClock.StreamClockTest do
  use ExUnit.Case

  import Hammox

  # These are for the doctest only ...
  doctest XestClock.StreamClock

  alias XestClock.StreamClock
  alias XestClock.Timestamp
  alias XestClock.TimeValue

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "XestClock.StreamClock" do
    test "new/2 refuses :native or unknown time units" do
      assert_raise(ArgumentError, fn ->
        StreamClock.new(:local, :native)
      end)

      assert_raise(ArgumentError, fn ->
        StreamClock.new(:local, :unknown_time_unit)
      end)
    end

    test "new/2 accepts usual Streams and does not infinitely loop" do
      #      # mocks expectations are needed since clock also tracks local time internally
      #      XestClock.System.ExtraMock
      #      |> expect(:native_time_unit, fn -> :millisecond end)
      #
      #      XestClock.System.OriginalMock
      #      |> expect(:time_offset, 2, fn _ -> 0 end)
      #      |> expect(:monotonic_time, fn :millisecond -> 1 end)
      #      |> expect(:monotonic_time, fn :millisecond -> 2 end)

      clock = StreamClock.new(:stream, :millisecond, Stream.repeatedly(fn -> 42 end))

      tick_list = clock |> Enum.take(2) |> Enum.to_list()

      assert tick_list == [
               %Timestamp{
                 origin: :stream,
                 ts: %TimeValue{monotonic: 42, offset: nil, skew: nil, unit: :millisecond}
               },
               %Timestamp{
                 origin: :stream,
                 ts: %TimeValue{monotonic: 42, offset: 0, skew: nil, unit: :millisecond}
               }
             ]
    end

    #    test "stream pipes increasing timestamp for clock" do
    #      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
    #        # mocks expectations are needed since clock also tracks local time internally
    ##        XestClock.System.ExtraMock
    ##        |> expect(:native_time_unit, fn -> unit end)
    ##
    ##        XestClock.System.OriginalMock
    ##        |> expect(:time_offset, 2, fn _ -> 0 end)
    ##        # Here we should be careful as internal callls to system,
    ##        # and actual clock calls are intermingled
    ##        # TODO : maybe get rid of this contrived test...
    #        |> expect(:monotonic_time, fn ^unit -> 1 end)
    #        |> expect(:monotonic_time, fn ^unit -> 1 end)
    #        |> expect(:monotonic_time, fn ^unit -> 2 end)
    #        |> expect(:monotonic_time, fn ^unit -> 2 end)
    #
    #        clock = StreamClock.new(:local, unit)
    #
    #        # Note : since we tick faster than unit here, we need to mock sleep.
    #        # but only when we are slower than milliseconds otherwise sleep(ms) is useless
    #        if unit == :second do
    #          XestClock.Process.OriginalMock
    #          |> expect(:sleep, fn _ -> :ok end)
    #        end
    #
    #        tick_list = clock |> Enum.take(2) |> Enum.to_list()
    #
    #        assert tick_list == [
    #                 %Timestamp{origin: :local, ts: %TimeValue{monotonic: 1, unit: unit}},
    #                 %Timestamp{origin: :local, ts: %TimeValue{monotonic: 2, unit: unit, offset: 1}}
    #               ]
    #      end
    #    end

    test "stream repeats the last integer if the current one is not greater" do
      # mocks expectations are needed since clock also tracks local time internally
      #      XestClock.System.ExtraMock
      #      |> expect(:native_time_unit, fn -> :nanosecond end)
      #
      #      XestClock.System.OriginalMock
      #      |> expect(:time_offset, 5, fn _ -> 0 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 1 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 2 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 3 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 4 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 5 end)

      clock = StreamClock.new(:testclock, :second, [1, 2, 3, 5, 4])

      #      XestClock.Process.OriginalMock
      #      # Note : since we tick faster than unit here, we need to mock sleep.
      #      |> expect(:sleep, 4, fn _ -> :ok end)

      assert clock |> Enum.to_list() == [
               %Timestamp{
                 origin: :testclock,
                 ts: %TimeValue{monotonic: 1, offset: nil, skew: nil, unit: :second}
               },
               %Timestamp{
                 origin: :testclock,
                 ts: %TimeValue{monotonic: 2, offset: 1, skew: nil, unit: :second}
               },
               %Timestamp{
                 origin: :testclock,
                 ts: %TimeValue{monotonic: 3, offset: 1, skew: 0, unit: :second}
               },
               %Timestamp{
                 origin: :testclock,
                 ts: %TimeValue{monotonic: 5, offset: 2, skew: 1, unit: :second}
               },
               %Timestamp{
                 origin: :testclock,
                 ts: %TimeValue{monotonic: 5, offset: 0, skew: nil, unit: :second}
               }
             ]
    end

    # TODO : with limiter
    #    test "stream doesnt tick faster than the unit" do
    #      for unit <- [:second, :millisecond, :microsecond, :nanosecond] do
    #        XestClock.System.OriginalMock
    #        |> expect(:monotonic_time, fn ^unit -> 1 end)
    #        |> expect(:monotonic_time, fn ^unit -> 2 end)
    #        |> expect(:monotonic_time, fn ^unit -> 3 end)
    #
    #        clock = StreamClock.new(:local, unit)
    #
    #        tick_list = clock |> Enum.take(2) |> Enum.to_list()
    # end

    test "stream returns increasing timestamp for clock using agent update as read function" do
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

      # mocks expectations are needed since clock also tracks local time internally
      #      XestClock.System.ExtraMock
      #      |> expect(:native_time_unit, fn -> :nanosecond end)
      #
      #      XestClock.System.OriginalMock
      #      |> expect(:time_offset, 4, fn _ -> 0 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 1 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 2 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 3 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 4 end)

      clock =
        StreamClock.new(
          :testclock,
          :nanosecond,
          Stream.repeatedly(fn -> ticker.() end)
        )

      # Note : we can take/2 only 4 elements (because of monotonicity constraint).
      # Attempting to take more will keep calling the ticker
      # and fail since the [] -> {nil, []} line is commented
      # TODO : taking more should stop the agent, and end the stream... REEALLY ??
      assert clock |> Stream.take(4) |> Enum.to_list() ==
               [
                 %Timestamp{
                   origin: :testclock,
                   ts: %TimeValue{monotonic: 1, offset: nil, skew: nil, unit: :nanosecond}
                 },
                 %Timestamp{
                   origin: :testclock,
                   ts: %TimeValue{monotonic: 2, offset: 1, skew: nil, unit: :nanosecond}
                 },
                 %Timestamp{
                   origin: :testclock,
                   ts: %TimeValue{monotonic: 3, offset: 1, skew: 0, unit: :nanosecond}
                 },
                 %Timestamp{
                   origin: :testclock,
                   ts: %TimeValue{monotonic: 5, offset: 2, skew: 1, unit: :nanosecond}
                 }
               ]
    end

    test "as_timestamp/1 transform the clock stream into a stream of monotonous timestamps." do
      # mocks expectations are needed since clock also tracks local time internally
      #      XestClock.System.ExtraMock
      #      |> expect(:native_time_unit, fn -> :nanosecond end)
      #
      #      XestClock.System.OriginalMock
      #      |> expect(:time_offset, 5, fn _ -> 0 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 1 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 2 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 3 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 4 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 5 end)

      clock = StreamClock.new(:testclock, :second, [1, 2, 3, 5, 4])

      #      XestClock.Process.OriginalMock
      #      # Note : since we tick faster than unit here, we need to mock sleep.
      #      |> expect(:sleep, 4, fn _ -> :ok end)

      assert clock |> Enum.to_list() ==
               [
                 %Timestamp{
                   origin: :testclock,
                   ts: %TimeValue{monotonic: 1, offset: nil, skew: nil, unit: :second}
                 },
                 %Timestamp{
                   origin: :testclock,
                   ts: %TimeValue{monotonic: 2, offset: 1, skew: nil, unit: :second}
                 },
                 %Timestamp{
                   origin: :testclock,
                   ts: %TimeValue{monotonic: 3, offset: 1, skew: 0, unit: :second}
                 },
                 %Timestamp{
                   origin: :testclock,
                   ts: %TimeValue{monotonic: 5, offset: 2, skew: 1, unit: :second}
                 },
                 %Timestamp{
                   origin: :testclock,
                   ts: %TimeValue{monotonic: 5, offset: 0, skew: nil, unit: :second}
                 }
                 # TODO : fix last skew here should not be nil, but negative...
               ]
    end

    test "convert/2 convert from one unit to another" do
      # mocks expectations are needed since clock also tracks local time internally
      #      XestClock.System.ExtraMock
      #      |> expect(:native_time_unit, fn -> :nanosecond end)

      #      XestClock.System.OriginalMock
      ##      |> expect(:time_offset, 5, fn _ -> 0 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 1 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 2 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 3 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 4 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 5 end)

      clock = StreamClock.new(:testclock, :second, [1, 2, 3, 5, 4])

      #      XestClock.Process.OriginalMock
      #      # Note : since we tick faster than unit here, we need to mock sleep.
      #      |> expect(:sleep, 4, fn _ -> :ok end)

      assert StreamClock.convert(clock, :millisecond)
             |> Enum.to_list() == [
               %Timestamp{origin: :testclock, ts: 1000},
               %Timestamp{origin: :testclock, ts: 2000},
               %Timestamp{origin: :testclock, ts: 3000},
               %Timestamp{origin: :testclock, ts: 5000},
               %Timestamp{origin: :testclock, ts: 5000}
             ]
    end

    #    test "offset/2 computes difference between clocks" do
    #      clock_a = StreamClock.new(:testclock_a, :second, [1, 2, 3, 5, 4])
    #      clock_b = StreamClock.new(:testclock_b, :second, [11, 12, 13, 15, 124])
    #
    #      assert clock_a |> StreamClock.offset(clock_b) ==
    #               %Timestamp{origin: :testclock_b, ts: 10, unit: :second}
    #    end
    #
    #    test "offset/2 of same clock is null" do
    #      clock_a = StreamClock.new(:testclock_a, :second, [1, 2, 3])
    #      clock_b = StreamClock.new(:testclock_b, :second, [1, 2, 3])
    #
    #      assert clock_a |> StreamClock.offset(clock_b) ==
    #               %Timestamp{origin: :testclock_b, ts: 0, unit: :second}
    #    end
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

    #    test "new/3 does return clock with offset of zero", %{
    #      ref: ref_seq
    #    } do
    #      ref = StreamClock.new(:refclock, :second, ref_seq)
    #
    #      assert %{ref | stream: ref.stream |> Enum.to_list()} == %StreamClock{
    #               origin: :refclock,
    #               unit: :second,
    #               stream: ref_seq,
    #               offset: %Timestamp{
    #                 origin: :refclock,
    #                 unit: :second,
    #                 ts: 0
    #               }
    #             }
    #    end
    #
    #    test "add_offset/2 adds the offset passed as parameter", %{
    #      clock: clock_seq,
    #      ref: ref_seq,
    #      expect: expected_offsets
    #    } do
    #      for i <- 0..4 do
    #        clock = StreamClock.new(:testremote, :second, clock_seq |> Enum.drop(i))
    #        ref = StreamClock.new(:refclock, :second, ref_seq |> Enum.drop(i))
    #
    #        offset =
    #          StreamClock.offset(
    #            ref,
    #            clock
    #          )
    #
    #        proxy =
    #          StreamClock.new(:refclock, :second, ref_seq |> Enum.drop(i))
    #          |> StreamClock.add_offset(offset)
    #
    #        # Enum. to_list() is used to compute the whole stream at once
    #        assert %{proxy | stream: proxy.stream |> Enum.to_list()} == %StreamClock{
    #                 origin: :refclock,
    #                 unit: :second,
    #                 stream: ref_seq |> Enum.drop(i),
    #                 offset: %Timestamp{
    #                   origin: :testremote,
    #                   unit: :second,
    #                   # this is only computed with one check of each clock
    #                   ts: expected_offsets |> Enum.at(i)
    #                 }
    #               }
    #      end
    #    end
    #
    #    test "add_offset/2 computes the time offset but for a proxy clock", %{
    #      clock: clock_seq,
    #      ref: ref_seq,
    #      expect: expected_offsets
    #    } do
    #      for i <- 0..4 do
    #        clock = StreamClock.new(:testremote, :second, clock_seq |> Enum.drop(i))
    #        ref = StreamClock.new(:refclock, :second, ref_seq |> Enum.drop(i))
    #
    #        proxy = ref |> StreamClock.follow(clock)
    #
    #        assert proxy
    #               # here we check one by one
    #               |> StreamClock.to_datetime(fn :second -> 42 end)
    #               |> Enum.at(0) ==
    #                 DateTime.from_unix!(
    #                   Enum.at(ref_seq, i) + 42 + Enum.at(expected_offsets, i),
    #                   :second
    #                 )
    #      end
    #    end

    #    @tag skip: true
    #    test "to_datetime/2 computes the current datetime for a clock", %{
    #      clock: clock_seq,
    #      ref: ref_seq,
    #      expect: expected_offsets
    #    } do
    #      # CAREFUL: we need to adjust the offset, as well as the next clock tick in the sequence
    #      # in order to get the simulated current datetime of the proxy
    #      expected_dt =
    #        expected_offsets
    #        |> Enum.zip(ref_seq |> Enum.drop(1))
    #        |> Enum.map(fn {offset, ref} ->
    #          DateTime.from_unix!(42 + offset + ref, :second)
    #        end)
    #
    #      # TODO : fix implementation... test seems okay ??
    #      for i <- 0..4 do
    #        clock = StreamClock.new(:testremote, :second, clock_seq |> Enum.drop(i))
    #        ref = StreamClock.new(:refclock, :second, ref_seq |> Enum.drop(i))
    #
    #        proxy = ref |> StreamClock.follow(clock)
    #
    #        assert proxy
    #               |> StreamClock.to_datetime(fn :second -> 42 end)
    #               |> Enum.to_list() == expected_dt
    #      end
    #    end
  end

  describe "Xestclock.StreamClock in a GenServer" do
    setup [:mocks, :test_stream, :stepper_setup]

    defp mocks(_) do
      #      # mocks expectations are needed since clock also tracks local time internally
      #      XestClock.System.ExtraMock
      #      |> expect(:native_time_unit, fn -> :nanosecond end)
      #
      #      XestClock.System.OriginalMock
      #      |> expect(:time_offset, 5, fn _ -> 0 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 1 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 2 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 3 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 4 end)
      #      |> expect(:monotonic_time, fn :nanosecond -> 5 end)

      # TODO : split expectations used at initialization and those used afterwards...
      # => maybe thoes used as initialization should be setup differently?
      # maybe via some other form of dependency injection ?

      %{mocks: [XestClock.System.OriginMock, XestClock.System.OriginalMock]}
    end

    defp test_stream(%{usecase: usecase}) do
      case usecase do
        :streamclock ->
          %{
            test_stream:
              StreamClock.new(
                :testclock,
                :millisecond,
                [1, 2, 3, 4, 5]
              )
          }
      end
    end

    defp stepper_setup(%{test_stream: test_stream, mocks: mocks}) do
      # We use start_supervised! from ExUnit to manage gen_stage
      # and not with the gen_stage :link option
      streamstpr = start_supervised!({StreamStepper, test_stream})

      # Setup allowance for stepper to access all mocks
      for m <- mocks do
        allow(m, self(), streamstpr)
      end

      %{streamstpr: streamstpr}
    end

    @tag usecase: :streamclock
    test "with StreamClock return proper Timestamp on tick()", %{streamstpr: streamstpr} do
      _before = Process.info(streamstpr)

      assert StreamStepper.tick(streamstpr) == %Timestamp{
               origin: :testclock,
               ts: %TimeValue{monotonic: 1, unit: :millisecond}
             }

      _first = Process.info(streamstpr)

      # Note the memory does NOT stay constant for a clock because of extra operations.
      # Lets just hope garbage collection works with it as expected (TODO : long running perf test in livebook)

      assert StreamStepper.tick(streamstpr) == %Timestamp{
               origin: :testclock,
               ts: %TimeValue{monotonic: 2, offset: 1, unit: :millisecond}
             }

      _second = Process.info(streamstpr)

      # Note the memory does NOT stay constant for a clockbecuase of extra operations.
      # Lets just hope garbage collection works with it as expected (TODO : long running perf test in livebook)

      assert StreamStepper.ticks(streamstpr, 3) == [
               %Timestamp{
                 origin: :testclock,
                 ts: %TimeValue{monotonic: 3, offset: 1, skew: 0.0, unit: :millisecond}
               },
               %Timestamp{
                 origin: :testclock,
                 ts: %TimeValue{monotonic: 4, offset: 1, skew: 0.0, unit: :millisecond}
               },
               %Timestamp{
                 origin: :testclock,
                 ts: %TimeValue{monotonic: 5, offset: 1, skew: 0.0, unit: :millisecond}
               }
             ]

      # TODO : seems we should return the last one instead of nil ??
      assert StreamStepper.tick(streamstpr) == nil
      # Note : the Process is still there (in case more data gets written into the stream...)
    end
  end
end

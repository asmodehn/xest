defmodule XestClock.Proxy.Test do
  use ExUnit.Case
  doctest XestClock.Proxy

  alias XestClock.Proxy
  alias XestClock.Clock
  alias XestClock.Timestamp

  describe "Xestclock.Proxy" do
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

    test "new/1 does set remote and set offset of zero", %{
      clock: clock_seq,
      ref: ref_seq,
      expect: expected_offsets
    } do
      clock = Clock.new(:testremote, :second, clock_seq)
      ref = Clock.new(:refclock, :second, ref_seq)

      assert Proxy.new(clock, ref) == %Proxy{
               remote: clock,
               reference: ref,
               offset: %Timestamp{
                 origin: :testremote,
                 unit: :second,
                 ts: 0
               }
             }
    end

    test "add_offset/1 does computes the offset if needed", %{
      clock: clock_seq,
      ref: ref_seq,
      expect: expected_offsets
    } do
      for i <- 0..4 do
        clock = Clock.new(:testremote, :second, clock_seq |> Enum.drop(i))
        ref = Clock.new(:refclock, :second, ref_seq |> Enum.drop(i))
        proxy = Proxy.new(clock, ref)

        assert Proxy.add_offset(
                 proxy,
                 Clock.offset(
                   proxy.reference,
                   clock
                 )
               ) == %Proxy{
                 remote: clock,
                 reference: ref,
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
        clock = Clock.new(:testremote, :second, clock_seq |> Enum.drop(i))
        ref = Clock.new(:refclock, :second, ref_seq |> Enum.drop(i))

        proxy =
          Proxy.new(clock, ref)
          |> Proxy.add_offset(
            Clock.offset(
              ref,
              clock
            )
          )

        assert proxy
               # here we check one by one
               |> Proxy.to_datetime(fn :second -> 42 end)
               |> Enum.at(0) ==
                 DateTime.from_unix!(
                   Enum.at(ref_seq, i) + 42 + Enum.at(expected_offsets, i),
                   :second
                 )
      end
    end

    @tag skip: true
    test "to_datetime/2 computes the current datetime for a proxy clock", %{
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
        clock = Clock.new(:testremote, :second, clock_seq |> Enum.drop(i))
        ref = Clock.new(:refclock, :second, ref_seq |> Enum.drop(i))

        proxy =
          Proxy.new(clock, ref)
          |> Proxy.add_offset(
            Clock.offset(
              ref,
              clock
            )
          )

        assert proxy
               |> Proxy.to_datetime(fn :second -> 42 end)
               |> Enum.to_list() == expected_dt
      end
    end
  end
end

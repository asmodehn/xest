defmodule XestClock.Stream.Timed.Proxy.Test do
  use ExUnit.Case
  doctest XestClock.Stream.Timed.Proxy

  #  import Hammox

  alias XestClock.Stream.Timed.Proxy
  #  alias XestClock.Stream.Timed.LocalStamp
  alias XestClock.Time
  #  alias XestClock.Stream.Timed

  describe "skew/2" do
    test "computes the ratio between two time offsets" do
      tv1 = %Time.Value{unit: :millisecond, value: 42, offset: 44}
      tv2 = %Time.Value{unit: :millisecond, value: 51, offset: 33}

      assert Proxy.skew(tv1, tv2) == 44 / 33
    end

    test "handles the unit conversion between two time offsets" do
      tv1 = %Time.Value{unit: :millisecond, value: 42, offset: 44}
      tv2 = %Time.Value{unit: :microsecond, value: 51000, offset: 33000}

      assert Proxy.skew(tv1, tv2) == 44 / 33
    end
  end

  describe "estimate_now" do
    test "compute current time estimation and error" do
      tv1 = %Time.Value{unit: :millisecond, value: 42, offset: 44}
      tv2 = %Time.Value{unit: :millisecond, value: 51, offset: 33}

      assert Proxy.estimate_now(tv1, tv2) == %Time.Value{
               unit: :millisecond,
               value: 42 + 33,
               offset: 33
             }
    end

    test "handles the unit conversion between two time values" do
      tv1 = %Time.Value{unit: :millisecond, value: 42, offset: 44}
      tv2 = %Time.Value{unit: :microsecond, value: 51000, offset: 33000}

      assert Proxy.estimate_now(tv1, tv2) == %Time.Value{
               unit: :millisecond,
               value: 42 + 33,
               offset: 33
             }
    end
  end

  #  describe "proxy/2" do
  #    test "let usual time value pair through, if estimation is not safe" do
  #      # setup the right mock to get proper values of localstamp
  #      XestClock.System.OriginalMock
  #      |> expect(:time_offset, 3, fn :millisecond -> 0 end)
  #      # called a forth time to generate the timestamp of the estimation
  #      |> expect(:time_offset, fn _ -> 0 end)
  #      |> expect(:monotonic_time, fn :millisecond -> 1 end)
  #      |> expect(:monotonic_time, fn :millisecond -> 2 end)
  #      |> expect(:monotonic_time, fn :millisecond -> 3 end)
  #      # called a forth time to generate the timestamp of the estimation
  #      # weakly monotonic !
  #      |> expect(:monotonic_time, fn _unit -> 3 end)
  #
  #      proxy =
  #        [
  #          %Time.Value{unit: :millisecond, value: 11},
  #          %Time.Value{unit: :millisecond, value: 13, offset: 2},
  #          %Time.Value{unit: :millisecond, value: 15, offset: 2}
  #        ]
  #        |> Stream.zip(
  #          Stream.repeatedly(fn -> LocalStamp.now(:millisecond) end)
  #          # we need to integrate previous value to compute derivative on the fly
  #          # TODO make this more obvious by putting it in a module...
  #          |> Stream.transform(nil, fn
  #            lts, nil -> {[lts], lts}
  #            lts, prev -> {[lts |> LocalStamp.with_previous(prev)], lts}
  #          end)
  #        )
  #        |> Proxy.proxy()
  #
  #      # computed skew is greater or equal to 1:
  #      assert Proxy.skew(
  #               %Time.Value{unit: :millisecond, value: 15, offset: 2},
  #               %Time.Value{unit: :millisecond, value: 3, offset: 1}
  #             ) >= 1
  #
  #      # meaning error is greater than local_offset
  #      # therefore estimation is ignored and original value is retrieved
  #
  #      assert proxy |> Enum.take(3) == [
  #               {%Time.Value{unit: :millisecond, value: 11},
  #                %LocalStamp{
  #                  monotonic: %Time.Value{unit: :millisecond, value: 1},
  #                  unit: :millisecond,
  #                  vm_offset: 0
  #                }},
  #               {%Time.Value{unit: :millisecond, value: 13, offset: 2},
  #                %LocalStamp{
  #                  monotonic: %Time.Value{unit: :millisecond, value: 2, offset: 1},
  #                  unit: :millisecond,
  #                  vm_offset: 0
  #                }},
  #               {%Time.Value{unit: :millisecond, value: 15, offset: 2},
  #                %LocalStamp{
  #                  monotonic: %Time.Value{unit: :millisecond, value: 3, offset: 1},
  #                  unit: :millisecond,
  #                  vm_offset: 0
  #                }}
  #             ]
  #    end
  #
  #    @tag :skip
  #    test "generates extra time value pair when it is safe to estimate" do
  #      #        XestClock.System.OriginalMock
  #      #        |> expect(:monotonic_time, fn unit -> 100 end)  # because proxy will check local (monotonic) time
  #      #        |> expect(:monotonic_time, fn unit -> 300 end)
  #
  #      proxy =
  #        [
  #          {%Time.Value{unit: :millisecond, value: 11}, %Time.Value{unit: :millisecond, value: 1}},
  #          {%Time.Value{unit: :millisecond, value: 191, offset: 180},
  #           %Time.Value{unit: :millisecond, value: 200, offset: 199}},
  #          {%Time.Value{unit: :millisecond, value: 391, offset: 200},
  #           %Time.Value{unit: :millisecond, value: 400, offset: 200}}
  #        ]
  #        |> Proxy.proxy()
  #
  #      # computed skew is less than 1:
  #      assert Proxy.skew(
  #               %Time.Value{unit: :millisecond, value: 391, offset: 200},
  #               %Time.Value{unit: :millisecond, value: 400, offset: 200}
  #             ) < 1
  #
  #      # meaning error is lower than local_offset
  #      # therefore estimation is passed in stream instead of retrieving original value
  #
  #      assert proxy |> Enum.to_list() == [
  #               {%Time.Value{unit: :millisecond, value: 11},
  #                %Time.Value{unit: :millisecond, value: 1}},
  #               {%Time.Value{unit: :millisecond, value: 191, offset: 180},
  #                %Time.Value{unit: :millisecond, value: 200, offset: 199}},
  #               {%Time.Value{unit: :millisecond, value: 391, offset: 200},
  #                %Time.Value{unit: :millisecond, value: 400, offset: 200}}
  #             ]
  #    end
  #
  #    test "with mocked local clock does not call it more than expected" do
  #      # setup the right mock to get proper values of localstamp
  #      XestClock.System.OriginalMock
  #      |> expect(:time_offset, 3, fn _ -> 0 end)
  #      # called a forth time to generate the timestamp of the estimation
  #      |> expect(:time_offset, fn _ -> 0 end)
  #      |> expect(:monotonic_time, fn _unit -> 100 end)
  #      |> expect(:monotonic_time, fn _unit -> 300 end)
  #      # TODO : get rid of this !
  #      |> expect(:monotonic_time, fn _unit -> 500 end)
  #      # called a forth? time to generate the timestamp of the estimation
  #      |> expect(:monotonic_time, fn _unit -> 500 end)
  #
  #      proxy =
  #        [100, 300, 500]
  #        |> Stream.map(fn e ->
  #          Time.Value.new(:millisecond, e)
  #        end)
  #        # TODO make this more obvious by putting it in a module...
  #        |> Stream.transform(nil, fn
  #          lts, nil -> {[lts], lts}
  #          lts, prev -> {[lts |> XestClock.Time.Value.with_previous(prev)], lts}
  #        end)
  #        # we depend on timed here ? (or maybe use simpler streams methods ?)
  #        |> Timed.timed(:millisecond)
  #        |> Proxy.proxy()
  #
  #      assert proxy |> Enum.take(3) == [
  #               {%XestClock.Time.Value{value: 100, offset: nil, unit: :millisecond},
  #                %XestClock.Stream.Timed.LocalStamp{
  #                  monotonic: %XestClock.Time.Value{
  #                    value: 100,
  #                    offset: nil,
  #                    unit: :millisecond
  #                  },
  #                  unit: :millisecond,
  #                  vm_offset: 0
  #                }},
  #               {%XestClock.Time.Value{value: 300, offset: 200, unit: :millisecond},
  #                %XestClock.Stream.Timed.LocalStamp{
  #                  monotonic: %XestClock.Time.Value{
  #                    value: 300,
  #                    offset: 200,
  #                    unit: :millisecond
  #                  },
  #                  unit: :millisecond,
  #                  vm_offset: 0
  #                }},
  #               # estimated value will get a nil as skew (current bug, but skew will disappear from struct)
  #               # So here we get the estimated value.
  #               # TODO : fix the issue where the mock is called, even though it s not needed !!!!
  #               {%XestClock.Time.Value{value: 500, offset: 200, unit: :millisecond},
  #                %XestClock.Stream.Timed.LocalStamp{
  #                  monotonic: %XestClock.Time.Value{
  #                    value: 500,
  #                    offset: 200,
  #                    unit: :millisecond
  #                  },
  #                  unit: :millisecond,
  #                  vm_offset: 0
  #                }}
  #             ]
  #    end
  #  end
end

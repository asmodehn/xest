defmodule XestClock.Stream.Timed.LocalDeltaTest do
  use ExUnit.Case
  doctest XestClock.Stream.Timed.LocalDelta

  #  import Hammox

  alias XestClock.Time
  alias XestClock.Stream.Timed

  describe "new/2" do
    test "compute difference between a teimstamp and a local timestamp" do
      assert Timed.LocalDelta.new(
               %Time.Stamp{
                 origin: :some_server,
                 ts: %Time.Value{
                   value: 42,
                   offset: 12,
                   unit: :millisecond
                 }
               },
               %Timed.LocalStamp{
                 unit: :millisecond,
                 monotonic: %Time.Value{
                   value: 1042,
                   offset: 14,
                   unit: :millisecond
                 },
                 vm_offset: 51
               }
             ) == %Timed.LocalDelta{
               offset: %Time.Value{
                 value: -1000,
                 offset: nil,
                 unit: :millisecond
               },
               skew: nil
             }
    end
  end

  #  describe "with_previous/2" do
  #    test " takes previous delta into account to compute the skew" do
  #      assert Timed.LocalDelta.with_previous(
  #               %Timed.LocalDelta{
  #                 offset: %Time.Value{
  #                   value: 1000,
  #                   offset: nil,
  #                   unit: :millisecond
  #                 },
  #                 skew: nil
  #               },
  #               %Timed.LocalDelta{
  #                 offset: %Time.Value{
  #                   value: 2000,
  #                   offset: nil,
  #                   unit: :millisecond
  #                 },
  #                 skew: nil
  #               }
  #             ) == %Timed.LocalDelta{
  #               offset: %Time.Value{
  #                 value: 1000,
  #                 offset: nil,
  #                 unit: :millisecond
  #               },
  #               skew: 0.5
  #             }
  #    end
  #  end

  describe "compute/1" do
    test "compute skew on a stream" do
      ts_enum = [
        %Time.Stamp{
          origin: :some_server,
          ts: %Time.Value{
            value: 42,
            offset: 12,
            unit: :millisecond
          }
        },
        %Time.Stamp{
          origin: :some_server,
          ts: %Time.Value{
            value: 51,
            offset: 9,
            unit: :millisecond
          }
        }
      ]

      lts_enum = [
        %Timed.LocalStamp{
          unit: :millisecond,
          monotonic: %Time.Value{
            value: 1042,
            offset: 14,
            unit: :millisecond
          },
          vm_offset: 51
        },
        %Timed.LocalStamp{
          unit: :millisecond,
          monotonic: %Time.Value{
            value: 1051,
            offset: 9,
            unit: :millisecond
          },
          vm_offset: 49
        }
      ]

      assert Timed.LocalDelta.compute(Stream.zip(ts_enum, lts_enum))
             |> Enum.to_list() ==
               Stream.zip([
                 ts_enum,
                 lts_enum,
                 [
                   %Timed.LocalDelta{
                     offset: %Time.Value{
                       value: -1000,
                       offset: nil,
                       unit: :millisecond
                     },
                     skew: nil
                   },
                   %Timed.LocalDelta{
                     offset: %Time.Value{
                       value: -1000,
                       offset: nil,
                       unit: :millisecond
                     },
                     # Zero since the offset between the clock is constant over time.
                     skew: 0.0
                   }
                 ]
               ])
               |> Enum.to_list()
    end
  end

  describe "error_since_at/2" do
    test "estimate the potential error" do
      delta = %Timed.LocalDelta{
        offset: %Time.Value{
          unit: :millisecond,
          value: 33
        },
        skew: 0.9
      }

      assert Timed.LocalDelta.error_since_at(
               delta,
               %Timed.LocalStamp{
                 unit: :millisecond,
                 monotonic: %Time.Value{
                   value: 42,
                   unit: :millisecond
                 },
                 vm_offset: 49
               },
               %Timed.LocalStamp{
                 unit: :millisecond,
                 monotonic: %Time.Value{
                   value: 51,
                   unit: :millisecond
                 },
                 vm_offset: 49
               }
             ) == Time.Value.new(:millisecond, round((51 - 42) * 0.9))
    end
  end
end

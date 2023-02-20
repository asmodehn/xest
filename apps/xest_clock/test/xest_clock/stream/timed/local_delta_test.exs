defmodule XestClock.Stream.Timed.LocalDeltaTest do
  use ExUnit.Case
  doctest XestClock.Stream.Timed.LocalDelta

  #  import Hammox

  alias XestClock.Time
  alias XestClock.Stream.Timed

  describe "new/2" do
    test "compute difference between a timestamp and a local timestamp" do
      assert Timed.LocalDelta.new(
               %Time.Value{
                 value: 42,
                 unit: :millisecond
               },
               %Timed.LocalStamp{
                 unit: :millisecond,
                 monotonic: 1042,
                 vm_offset: 51
               }
             ) == %Timed.LocalDelta{
               offset: %Time.Value{
                 # Note: vm_offset is taken into account
                 value: -1051,
                 unit: :millisecond
               },
               skew: nil
             }
    end
  end

  describe "compute/1" do
    test "compute skew on a stream" do
      tv_enum = [
        %Time.Value{
          value: 42,
          unit: :millisecond
        },
        %Time.Value{
          value: 51,
          unit: :millisecond
        }
      ]

      lts_enum = [
        %Timed.LocalStamp{
          unit: :millisecond,
          monotonic: 1042,
          vm_offset: 51
        },
        %Timed.LocalStamp{
          unit: :millisecond,
          monotonic: 1050,
          vm_offset: 52
        }
      ]

      assert Timed.LocalDelta.compute(Stream.zip(tv_enum, lts_enum))
             |> Enum.to_list() ==
               Stream.zip([
                 tv_enum,
                 lts_enum,
                 [
                   %Timed.LocalDelta{
                     offset: %Time.Value{
                       value: -1051,
                       unit: :millisecond
                     },
                     skew: nil
                   },
                   %Timed.LocalDelta{
                     offset: %Time.Value{
                       value: -1051,
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

  describe "offset_at/2" do
    test "estimate the offset with a potential error, keeping best unit" do
      delta = %Timed.LocalDelta{
        offset: %Time.Value{
          unit: :millisecond,
          value: 33
        },
        skew: 0.9
      }

      assert Timed.LocalDelta.offset_at(
               delta,
               %Timed.LocalStamp{
                 unit: :nanosecond,
                 monotonic: 42_000_000,
                 vm_offset: 49_000_000
               },
               %Timed.LocalStamp{
                 unit: :nanosecond,
                 monotonic: 51_000_000,
                 vm_offset: 49_000_000
               }
             ) ==
               Time.Value.new(
                 # Note we want maximum precision here,
                 # to make sure adjustment is visible
                 :nanosecond,
                 # offset measured last + estimated
                 33_000_000 + round((51_000_000 - 42_000_000) * 0.9),
                 # error: part that is estimated and a potential error
                 round((51_000_000 - 42_000_000) * 0.9)
               )
    end
  end
end

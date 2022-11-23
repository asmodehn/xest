defmodule XestClock.Record.Sync.Test do
  use ExUnit.Case
  doctest XestClock.Record.Sync

  alias XestClock.Record

  describe "Record.Sync" do
    setup do
      # TODO : sequenced clock for valid testing...
      clock =
        XestClock.Clock.new(:testing, :millisecond, fn -> System.monotonic_time(:millisecond) end)

      %{clock: clock}
    end

    test "new/1 accepts the testing clock",
         %{clock: clock} do
      rec = Record.Sync.new(clock)
      assert rec.clock == clock
      assert rec.events == []
    end

    test "Enum.into recognizes the Collectible implementation",
         %{clock: clock} do
      rec = Record.Sync.new(clock)
      assert rec.clock == clock

      updated_rec = [:something, :happened] |> Enum.into(rec)

      assert updated_rec.events == [
               %XestClock.Event.Local{
                 at: %XestClock.Clock.Timestamp{
                   origin: :testing,
                   ts: -576_460_750_813,
                   unit: :millisecond
                 },
                 data: :something
               },
               %XestClock.Event.Local{
                 at: %XestClock.Clock.Timestamp{
                   origin: :testing,
                   ts: -576_460_750_812,
                   unit: :millisecond
                 },
                 data: :happened
               }
             ]
    end
  end
end

defmodule Xest.ShadowClock.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.ShadowClock

  # WARNING : remote date precision determines future date computation precision
  @utc_remote_datetime ~U[2020-10-31 19:59:03.000Z]

  describe """
  Given a known fixed remote and local UTC clock, at microsecond precision
  """ do
    setup do
      clock =
        ShadowClock.new(
          fn -> @utc_remote_datetime end,
          fn -> ~U[2020-10-31 19:59:51.123Z] end
        )

      %{shadow: clock}
    end

    test """
         When directly requesting the time now,
         Then we get remote time
         """,
         %{shadow: clock} do
      assert ShadowClock.now(clock) == @utc_remote_datetime
    end

    test """
         When incrementing the local clock,
         Then we get remote time computed with offset, at micro second precision
         """,
         %{
           shadow: clock
         } do
      {offset_secs, offset_usecs} = Time.to_seconds_after_midnight(~T[00:01:01.101])

      incremented_clock =
        clock.local_clock.()
        |> DateTime.add(offset_secs, :second)
        |> DateTime.add(offset_usecs, :microsecond)

      assert ShadowClock.now(
               clock
               |> Map.put(:local_clock, fn -> incremented_clock end)
             ) ==
               @utc_remote_datetime
               |> DateTime.add(offset_secs, :second)
               |> DateTime.add(offset_usecs, :microsecond)
    end
  end
end

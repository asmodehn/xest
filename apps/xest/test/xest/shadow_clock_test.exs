defmodule Xest.ShadowClock.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.ShadowClock

  # WARNING : remote date precision determines future date computation precision
  # TODO : TimeX bug report ?
  @utc_remote_datetime ~U[2020-10-31 19:59:03.000000Z]
  @utc_local_datetime ~U[2020-10-31 19:59:51.123456Z]

  describe """
  Given a known fixed remote and local UTC clock, at microsecond precision
  """ do
    setup do
      clock =
        ShadowClock.new(
          fn -> @utc_remote_datetime end,
          fn -> @utc_local_datetime end
        )

      %{shadow: clock}
    end

    test """
         When requesting the time now,
         Then we get local utc time
         """,
         %{shadow: clock} do
      assert ShadowClock.now(clock) == @utc_local_datetime
    end

    test """
         When incrementing the local clock after a first now() request
         Then we get remote time computed with offset, at micro second precision
         """,
         %{
           shadow: clock
         } do
      # request update to retrieve remote clock at @utc_local_datetime
      clock = ShadowClock.update(clock)

      {offset_secs, offset_usecs} = Time.to_seconds_after_midnight(~T[00:01:01.102034])

      incremented_clock =
        clock.local_clock.()
        |> DateTime.add(offset_secs, :second)
        |> DateTime.add(offset_usecs, :microsecond)

      assert incremented_clock == ~U[2020-10-31 20:00:52.225490Z]

      # subsequent now() call will interpolate, given the previous known remote clock.
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

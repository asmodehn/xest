defmodule XestKraken.Clock.State.Test do
  use ExUnit.Case, async: true

  alias XestKraken.Clock

  import Hammox

  setup do
    # saving Xest.DateTime implementation
    previous = Application.get_env(:xest, :datetime_module)
    # Setup Xest.DateTime Mock for these tests
    Application.put_env(:xest, :datetime_module, Xest.DateTime.Mock)

    on_exit(fn ->
      # restoring config
      Application.put_env(:xest, :datetime_module, previous)
    end)
  end

  describe "Given the remote clock remains at default value, ie. local clock" do
    setup do
      clock_state = Clock.State.new()

      %{state: clock_state}
    end

    test "By default skew is 0", %{state: clock_state} do
      # by default
      assert clock_state.skew == Timex.Duration.from_microseconds(0)
    end

    test "when retrieving local clock, skew remains at exactly 0", %{state: clock_state} do
      Xest.DateTime.Mock
      |> expect(:utc_now, fn -> ~U[2020-02-02 02:02:02.202Z] end)

      skew = clock_state |> Clock.State.retrieve() |> Map.get(:skew)
      assert skew == Timex.Duration.from_microseconds(0)

      Xest.DateTime.Mock
      # retrieve
      |> expect(:utc_now, fn -> ~U[2020-02-02 02:02:02.202Z] end)

      skew = clock_state |> Clock.State.retrieve() |> Map.get(:skew)
      assert skew == Timex.Duration.from_microseconds(0)
    end

    test "when asking for expiration, it is false (no ttl)", %{state: clock_state} do
      expired = clock_state |> Clock.State.expired?()
      assert expired == false
    end

    test "when asking for expiration after retrieve, it is false (no ttl)", %{state: clock_state} do
      Xest.DateTime.Mock
      # retrieve
      |> expect(:utc_now, fn -> ~U[2020-02-02 02:02:02.202Z] end)
      # expiration check (1 day diff)
      |> expect(:utc_now, fn -> ~U[2020-02-03 02:02:02.202Z] end)

      expired = clock_state |> Clock.State.retrieve() |> Clock.State.expired?()
      assert expired == false
    end

    test "when we add a ttl, state is expired by default (never rtrieved)", %{state: clock_state} do
      state_with_ttl = clock_state |> Clock.State.ttl(Timex.Duration.from_minutes(5))
      assert state_with_ttl |> Clock.State.expired?() == true
    end

    test "when we add a ttl, after a retrieval, state expires if utc_now request happens too late",
         %{state: clock_state} do
      Xest.DateTime.Mock
      # retrieve
      |> expect(:utc_now, fn -> ~U[2020-02-02 02:02:02.202Z] end)

      state_retrieved =
        clock_state |> Clock.State.ttl(Timex.Duration.from_minutes(5)) |> Clock.State.retrieve()

      # 2 minutes later
      assert Clock.State.expired?(state_retrieved, ~U[2020-02-02 02:04:02.202Z]) == false
      # 10 minutes later
      assert Clock.State.expired?(state_retrieved, ~U[2020-02-02 02:12:02.202Z]) == true
    end
  end
end

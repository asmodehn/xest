defmodule XestBinance.Clock.Test do
  use ExUnit.Case, async: true

  alias XestBinance.Clock
  alias XestBinance.Adapter

  import Hammox

  setup do
    # saving XestClock.DateTime implementation
    previous_datetime = Application.get_env(:xest_clock, :datetime_module)
    # Setup XestClock.DateTime Mock for these tests
    Application.put_env(:xest_clock, :datetime_module, XestClock.DateTime.Mock)

    on_exit(fn ->
      # restoring config
      Application.put_env(:xest_clock, :datetime_module, previous_datetime)
    end)
  end

  describe "Given the clock has no ttl," do
    setup do
      # setting up client to pass adapter mock
      client = Adapter.client() |> Adapter.Client.with_adapter(Adapter.Mock.Clock)

      clock_pid =
        start_supervised!({
          Clock,
          # passing nil as we rely on a mock here.
          ttl: nil,
          name: String.to_atom("#{__MODULE__}.Process"),
          remote: fn -> Adapter.servertime(client).servertime() end
        })

      # setting up DateTime mock allowance for the clock process
      XestClock.DateTime.Mock
      |> allow(self(), clock_pid)

      %{clock_pid: clock_pid}
    end

    test "utc_now simply returns the local clock (no retrieval attempt)", %{clock_pid: clock_pid} do
      XestClock.DateTime.Mock
      # local now, just once
      |> expect(:utc_now, fn -> ~U[2020-02-02 02:02:02.202Z] end)

      now = Clock.utc_now(clock_pid)
      assert now == ~U[2020-02-02 02:02:02.202Z]
    end
  end

  describe "Given the remote clock is nil (local, implicitely), with ttl," do
    setup do
      clock_pid =
        start_supervised!({
          Clock,
          # passing nil as we rely on a mock here.
          remote: nil, ttl: :timer.minutes(5), name: String.to_atom("#{__MODULE__}.Process")
        })

      # setting up DateTime mock allowance for the clock process
      XestClock.DateTime.Mock
      |> allow(self(), clock_pid)

      %{clock_pid: clock_pid}
    end

    test "utc_now returns the local clock after noop retrieval, no skew added", %{
      clock_pid: clock_pid
    } do
      XestClock.DateTime.Mock
      # local now() to check for expiration and timestamp request
      |> expect(:utc_now, fn -> ~U[2020-02-02 02:02:02.202Z] end)
      # local now to add 0 skew
      |> expect(:utc_now, fn -> ~U[2020-02-02 02:02:03.202Z] end)

      now = Clock.utc_now(clock_pid)
      assert now == ~U[2020-02-02 02:02:03.202Z]

      # checking state
      state =
        Agent.get(clock_pid, fn state ->
          state
        end)

      assert state.requested_on == ~U[2020-02-02 02:02:02.202Z]
      # skew is
      assert state.skew == Timex.Duration.from_microseconds(0)
    end
  end

  describe "Given the remote clock is set to a datetime mock, with ttl," do
    setup do
      clock_pid =
        start_supervised!({
          Clock,
          # passing nil as we rely on a mock here.
          remote: &XestClock.DateTime.Mock.utc_now/0,
          ttl: :timer.minutes(5),
          name: String.to_atom("#{__MODULE__}.Process")
        })

      # setting up DateTime mock allowance for the clock process
      XestClock.DateTime.Mock
      |> allow(self(), clock_pid)

      %{clock_pid: clock_pid}
    end

    test "utc_now returns the local clock after retrieval with skew added", %{
      clock_pid: clock_pid
    } do
      XestClock.DateTime.Mock
      # local now() to check for expiration
      |> expect(:utc_now, fn -> ~U[2020-02-02 02:02:02.202Z] end)
      # retrieve()
      |> expect(:utc_now, fn -> ~U[2020-02-02 02:02:03.202Z] end)
      # local now to add skew
      |> expect(:utc_now, fn -> ~U[2020-02-02 02:02:04.202Z] end)

      now = Clock.utc_now(clock_pid)

      # getting internal skew from agent state
      # skew computed internally via Timex.measure (tricky to mock or predict)
      state =
        Agent.get(clock_pid, fn state ->
          state
        end)

      assert state.requested_on == ~U[2020-02-02 02:02:02.202Z]
      # verify now is actually the last local utc_now call with the skew added
      assert now == Timex.add(~U[2020-02-02 02:02:04.202Z], state.skew)
    end
  end

  describe "Given the remote clock is set to an adapter mock, with ttl," do
    setup do
      # setting up client to pass adapter mock
      client = Adapter.client() |> Adapter.Client.with_adapter(Adapter.Mock.Clock)

      clock_pid =
        start_supervised!({
          Clock,
          # passing nil as we rely on a mock here.
          remote: fn -> Adapter.servertime(client).servertime end,
          ttl: :timer.minutes(5),
          name: String.to_atom("#{__MODULE__}.Process")
        })

      # setting up DateTime mock allowance for the clock process
      XestClock.DateTime.Mock
      |> allow(self(), clock_pid)

      Adapter.Mock.Clock
      |> allow(self(), clock_pid)

      %{clock_pid: clock_pid}
    end

    # TODO : this test breaks sometimes ? race condition ?
    #  ** (exit) exited in: GenServer.call(#PID<0.650.0>, {:get_and_update, #Function<2.31306925/1 in XestBinance.Clock.utc_now/1>}, 5000)
    test "utc_now returns the local clock after retrieval with skew added", %{
      clock_pid: clock_pid
    } do
      XestClock.DateTime.Mock
      # local now() to check for expiration
      |> expect(:utc_now, fn -> ~U[2020-02-02 02:02:02.202Z] end)

      Adapter.Mock.Clock
      # retrieve()
      |> expect(:servertime, fn _ ->
        {:ok, ~U[2020-02-02 02:01:03.202Z]}
      end)

      XestClock.DateTime.Mock
      # local now to add skew
      |> expect(:utc_now, fn -> ~U[2020-02-02 02:02:04.202Z] end)

      now = Clock.utc_now(clock_pid)

      # getting internal skew from agent state
      # skew computed internally via Timex.measure (tricky to mock or predict)
      state =
        Agent.get(clock_pid, fn state ->
          state
        end)

      assert state.requested_on == ~U[2020-02-02 02:02:02.202Z]
      # verify now is actually the last local utc_now call with the skew added
      assert now == Timex.add(~U[2020-02-02 02:02:04.202Z], state.skew)
      # because the retrieved remote time is "before", we should have
      assert now < ~U[2020-02-02 02:02:02.202Z]
    end
  end
end

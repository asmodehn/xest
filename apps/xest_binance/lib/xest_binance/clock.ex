defmodule XestBinance.Clock do
  alias Xest.Clock.Proxy
  use Agent

  @default_ttl Timex.Duration.from_minutes(5)

  defmodule Behaviour do
    @moduledoc """
    A behaviour to allow mocks when multiprocess tests are not desired.
    """

    @type mockable_pid :: nil | pid()

    @callback utc_now(mockable_pid) :: XestClock.DateTime.t()
  end

  @behaviour Behaviour

  def start_link(opts) do
    {remote, opts} =
      Keyword.pop(
        opts,
        :remote,
        # defaults to retrieving unixtime from the adapter's servertime response
        fn -> XestBinance.Adapter.servertime().servertime() end
      )

    {ttl, opts} = Keyword.pop(opts, :ttl, @default_ttl)

    Agent.start_link(
      fn ->
        Proxy.new(remote)
        |> Proxy.ttl(ttl)
      end,
      opts
    )
  end

  @impl true
  def utc_now(agent \\ __MODULE__) do
    Agent.get_and_update(agent, fn state ->
      now = XestClock.DateTime.utc_now()

      # TODO :make state work for any connector ??
      if Proxy.expired?(state, now) do
        updated = state |> Proxy.retrieve(now)
        # significant time has passed, we should call utc_now again
        {Timex.add(XestClock.DateTime.utc_now(), updated.skew), updated}
      else
        {Timex.add(now, state.skew), state}
      end
    end)
  end
end

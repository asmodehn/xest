defmodule XestKraken.Clock do
  alias XestKraken.Clock.State
  use Agent

  @default_ttl Timex.Duration.from_minutes(5)

  defmodule Behaviour do
    @moduledoc """
    A behaviour to allow mocks when multiprocess tests are not desired.
    """

    @type reason :: String.t()

    @type mockable_pid :: nil | pid()

    # | {:error, reason}
    @callback utc_now(mockable_pid) :: Xest.DateTime.t()

    # TODO : by leveraging __using__ we could implement default function
    #                                   and their unsafe counterparts maybe ?
  end

  @behaviour Behaviour

  def start_link(opts) do
    {remote, opts} =
      Keyword.pop(
        opts,
        :remote,
        # defaults to retrieving unixtime from the adapter's servertime response
        fn -> XestKraken.Adapter.servertime().unixtime end
      )

    {ttl, opts} = Keyword.pop(opts, :ttl, @default_ttl)

    Agent.start_link(
      fn ->
        State.new(remote)
        |> State.ttl(ttl)
      end,
      opts
    )
  end

  @impl true
  def utc_now(agent \\ __MODULE__) do
    Agent.get_and_update(agent, fn state ->
      now = Xest.DateTime.utc_now()

      if State.expired?(state, now) do
        updated = state |> State.retrieve(now)
        # significant time has passed, we should call utc_now again
        {Timex.add(Xest.DateTime.utc_now(), updated.skew), updated}
      else
        {Timex.add(now, state.skew), state}
      end
    end)
  end
end

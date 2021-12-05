defmodule XestBinance.Account do
  @moduledoc """
    The private part of the client (specific to an account, should not be cached)

  """

  defmodule Behaviour do
    @moduledoc """
      this implements a conversion from Binance model into our Xest model.
      It serves to specify the types that must be exposed by a GenServer,
      where a better type can provide useful semantics.
      But it remains tied to the Binance model in its overall structure.
    """

    @type reason :: String.t()

    @type mockable_pid :: nil | pid() | atom()

    # | {:error, reason}
    @callback balance(mockable_pid()) :: Xest.Account.Balance.t()
    @callback trades(mockable_pid(), String.t()) :: Xest.TradesHistory.t()

    # TODO : by leveraging __using__ we could implement default function
    #                                   and their unsafe counterparts maybe ?
  end

  @behaviour Behaviour

  # these are the minimal amount of state necessary
  # to estimate current real world binance exchange status
  @enforce_keys [:auth_pid]
  defstruct auth_mod: nil,
            # pointing to the kraken client pid
            auth_pid: nil,
            balance: nil,
            trades: []

  use Agent

  def start_link(opts) do
    # :auth_mod is optional, but should point to module by default, or maybe be overridden
    {auth_mod, opts} = Keyword.pop(opts, :auth_mod, XestBinance.Auth)

    # :auth_pid should be the auth server pid.
    # if there is only one (current case), the mod can be used instead.
    {auth_pid, opts} = Keyword.pop(opts, :auth_pid, auth_mod)

    # REMINDER : we dont want to call external systems on startup.
    # Other processes need to align before this can safely happen in various environments.

    # starting the agent by passing the struct as initial value
    # - mocks should manually modify the initial struct if needed
    account_struct = %XestBinance.Account{
      auth_mod: auth_mod,
      auth_pid: auth_pid
    }

    Agent.start_link(
      fn -> account_struct end,
      opts
    )
  end

  @impl true
  def balance(agent) do
    # TODO : have some refresh to avoid too big delta over time...
    Agent.get_and_update(agent, fn state ->
      case state.balance do
        # when default initial balance (no valid account)
        balance when balance == nil ->
          {:ok, acc} = state.auth_mod.account(state.auth_pid)

          # doing some translation here, like an ACL...
          xest_balance = Xest.Account.Balance.ACL.new(acc)

          {xest_balance,
           state
           |> Map.put(
             :balance,
             xest_balance
           )}

        # TODO : check update time to eventually force refresh...

        balance ->
          {balance, state}
          # TODO : add a case to check for timeout to request again the status
      end
    end)
  end

  @impl true
  def trades(agent, symbol) do
    # TODO : have some refresh to avoid too big delta over time...
    Agent.get_and_update(agent, fn state ->
      case state.trades do
        # when default initial model (no valid account)
        tds when tds == [] ->
          {:ok, trades} = state.auth_mod.trades(state.auth_pid, symbol)

          # doing some translation here
          xest_trades = Xest.Account.TradesHistory.ACL.new(trades)

          {xest_trades, state |> Map.put(:trades, xest_trades)}

        # TODO : check update time to eventually force refresh...

        model ->
          {model, state}
          # TODO : add a case to check for timeout to request again the status
      end
    end)
  end
end

defmodule XestKraken.Account do
  @moduledoc """
    The private part of the client (specific to an account, should not be cached)

  """

  defmodule Behaviour do
    @moduledoc """
      this implements a conversion from Kraken model into our Xest model.
      It serves to specify the types that must be exposed by a GenServer,
      where a better type can provide useful semantics.
      But it remains tied to the Kraken model in its overall structure.
    """

    @type balance :: list(map())
    @type reason :: String.t()

    @type mockable_pid :: nil | pid() | atom()

    # | {:error, reason}
    @callback balance(mockable_pid()) :: Xest.Account.Balance.t()

    # TODO : by leveraging __using__ we could implement default function
    #                                   and their unsafe counterparts maybe ?
  end

  @behaviour Behaviour

  # these are the minimal amount of state necessary
  # to estimate current real world binance exchange status
  @enforce_keys [:authsrv]
  defstruct balance: nil,
            # pointing to the binance client pid
            authsrv: nil

  use Agent

  def start_link(opts) do
    {authsrv, opts} = Keyword.pop(opts, :auth, kraken_auth())
    # REMINDER : we dont want to call external systems on startup.
    # Other processes need to align before this can safely happen in various environments.

    # starting the agent by passing the struct as initial value
    # - mocks should manually modify the initial struct if needed
    account_struct = %XestKraken.Account{
      authsrv: authsrv
    }

    Agent.start_link(
      fn -> account_struct end,
      opts
    )
  end

  defp kraken_auth do
    Application.get_env(:xest, :kraken_auth, XestKraken.Auth)
  end

  @impl true
  def balance(agent) do
    # TODO : have some refresh to avoid too big delta over time...
    Agent.get_and_update(agent, fn state ->
      case state.balance do
        # when default initial model (no valid account)
        bal when bal == nil ->
          {:ok, balance} = kraken_auth().balance(state.authsrv)

          # doing some translation here, like an ACL...
          xest_balance =
            balance
            |> Map.update!(:balances, fn bl ->
              bl |> Enum.map(&Xest.Account.AssetBalance.ACL.new/1)
            end)
            |> Xest.Account.Balance.ACL.new()

          {xest_balance, state |> Map.put(:balance, xest_balance)}

        # TODO : check update time to eventually force refresh...

        model ->
          {model, state}
          # TODO : add a case to check for timeout to request again the status
      end
    end)
  end
end

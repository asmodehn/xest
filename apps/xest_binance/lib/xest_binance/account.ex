defmodule XestBinance.Account do
  @moduledoc """
    The private part of the client (specific to an account, should not be cached)

  """

  @behaviour XestBinance.Ports.AccountBehaviour

  # these are the minimal amount of state necessary
  # to estimate current real world binance exchange status
  @enforce_keys []
  defstruct model: nil,
            # pointing to the binance client pid
            authsrv: nil

  use Agent

  def start_link(opts) do
    {authsrv, opts} = Keyword.pop(opts, :authenticated, binance_authenticated())
    # REMINDER : we dont want to call external systems on startup.
    # Other processes need to align before this can safely happen in various environments.

    # starting the agent by passing the struct as initial value
    # - mocks should manually modify the initial struct if needed
    account_struct = %XestBinance.Account{
      authsrv: authsrv
    }

    Agent.start_link(
      fn -> account_struct end,
      opts
    )
  end

  defp binance_authenticated do
    Application.get_env(:xest, :binance_authenticated)
  end

  def model(agent) do
    Agent.get(agent, fn state -> state.model end)
  end

  # TODO : these 2 should be the same...
  @doc """
  Access the state of the exchange agent.
  This encodes our knowledge of binance exchange
  """
  def state(account) do
    Agent.get(account, &Function.identity/1)
  end

  @impl true
  def account(agent) do
    # TODO : have some refresh to avoid too big delta over time...
    Agent.get_and_update(agent, fn state ->
      case state.model do
        # when default initial model (no valid account)
        model when model == nil ->
          {:ok, acc} = binance_authenticated().account(state.authsrv)

          # doing some translation here, like an ACL...
          xest_acc = binance_to_xest_models(acc)

          {xest_acc,
           state
           |> Map.put(
             :model,
             xest_acc
           )}

        # TODO : check update time to eventually force refresh...

        model ->
          {model, state}
          # TODO : add a case to check for timeout to request again the status
      end
    end)
  end

  defp binance_to_xest_models(%Binance.Account{} = binance) do
    # TODO this should probably be in some ACL...
    Xest.Account.new(
      binance.balances,
      binance.maker_commission,
      binance.taker_commission,
      binance.buyer_commission,
      binance.seller_commission,
      binance.can_trade,
      binance.can_withdrawl,
      binance.can_deposit,
      binance.update_time
      #    binance.account_type,
      #    binance.permissions
    )
  end
end

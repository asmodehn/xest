defmodule XestBinance.MonadicAccount do
  @moduledoc """
    The private part of the client (specific to an account)
    Implemented as a State monad, instead of an agent.
  """

  #  @behaviour XestBinance.Ports.AccountBehaviour

  # these are the minimal amount of state necessary
  # to estimate current real world binance exchange status
  @enforce_keys [:authsrv]
  defstruct model: nil,
            # pointing to the binance client pid
            authsrv: nil

  # TODO : add retrieval local datetime...

  use Witchcraft

  import Algae.State

  def new(authsrv \\ binance_authenticated(), authsrv_pid \\ binance_authenticated()) do
    state(fn _utc_now ->
      # TODO : use utc_now to figure out if retrieving is needed or not.
      # TODO : leverage elixir's 'with' ?
      {:ok, acc_raw} = authsrv.account(authsrv_pid)
      model = binance_to_xest_models(acc_raw)
      data = %__MODULE__{model: model, authsrv: authsrv}
      {model, data}
    end)

    # TODO: same function written with monadic do
    #  %State{}
    #    |> monad do
    ##        utc_now <- get()
    ## TODO : if now is too recent, retrieve again...
    #        raw <- authsrv.account()
    #        model <- binance_to_xest_models(raw)
    #
    #        State.put(%__MODULE__{model: model, authsrv: authsrv})
    #
    #        return model
    #     end
  end

  def account(state, utc_now \\ &DateTime.utc_now/0) do
    state |> evaluate(utc_now.())
  end

  def inspect(state, utc_now \\ &DateTime.utc_now/0) do
    state |> execute(utc_now.())
  end

  defp binance_authenticated do
    Application.get_env(:xest, :binance_authenticated)
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

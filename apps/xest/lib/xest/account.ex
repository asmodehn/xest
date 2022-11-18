defmodule Xest.Account do
  @moduledoc """
    defines an account structure with ADT
  """

  defmodule Behaviour do
    @moduledoc "Behaviour to allow mocking a xest account for tests"
    @callback balance(atom()) :: %Xest.Account.Balance{}
    @callback balance(atom(), Keyword.t()) :: %Xest.Account.Balance{}
    @callback transactions(atom()) :: %Xest.Account.TradesHistory{}
    @callback transactions(atom(), String.t()) :: %Xest.Account.TradesHistory{}
  end

  def balance(connector, opts \\ [filter: fn x -> Float.round(x, 8) != 0 end]) do
    Xest.Account.Adapter.retrieve(connector, :balance)
    |> Map.update!(
      :balances,
      &Enum.filter(&1, fn b ->
        {free, ""} = Float.parse(b.free)
        {locked, ""} = Float.parse(b.locked)
        opts[:filter].(free) or opts[:filter].(locked)
      end)
    )
  end

  ## OLD version: all trades (kraken)
  def transactions(connector) do
    Xest.Account.Adapter.retrieve(connector, :trades)
  end

  ## WIP : trades for a symbol
  def transactions(connector, symbol) do
    Xest.Account.Adapter.retrieve(connector, :trades, symbol)
    |> IO.inspect()
  end
end

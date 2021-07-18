defmodule Xest.Account do
  @moduledoc """
    defines an account structure with ADT
  """

  defmodule Behaviour do
    @moduledoc "Behaviour to allow mocking a xest account for tests"
    @callback balance(atom()) :: %Xest.Account.Balance{}
  end

  def balance(connector) do
    Xest.Account.Adapter.retrieve(connector, :balance)
  end
end

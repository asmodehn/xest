defmodule Xest.Kraken.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Exchange

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox

  test "kraken status works" do
    XestKraken.Exchange.Mock
    |> expect(:status, fn _ ->
      %XestKraken.Exchange.Status{}
    end)

    assert Exchange.status(:kraken) == %Xest.Exchange.Status{
             description: "maintenance",
             status: :maintenance
           }
  end
end

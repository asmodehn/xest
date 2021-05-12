defmodule Xest.DateTime.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.DateTime

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: Xest.DateTime, behaviour: Xest.DateTime.Behaviour

  setup :verify_on_exit!

  test "DateTime.utc_now is mockable like any mock" do
    DateTimeMock
    |> expect(:utc_now, fn -> ~U[1970-01-01 01:01:01Z] end)

    assert DateTime.utc_now() == ~U[1970-01-01 01:01:01Z]
  end
end

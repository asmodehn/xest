defmodule XestBinance.Adapter.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  #  alias Xest.ShadowClock

  alias XestKraken.Adapter

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "system_status" do
    Adapter.Mock
    |> expect(
      :system_status,
      fn _ ->
        {:ok,
         %{
           "status" => "online",
           "timestamp" => "2021-05-31T08:50:01Z"
         }}
      end
    )

    assert Adapter.system_status() == %XestKraken.Exchange.Status{
             status: "online",
             timestamp: ~U[2021-05-31T08:50:01Z]
           }
  end
end

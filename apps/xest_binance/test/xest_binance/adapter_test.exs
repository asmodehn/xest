defmodule XestBinance.Adapter.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  #  alias Xest.ShadowClock

  alias XestBinance.Adapter

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "provides system status" do
    Adapter.Mock
    |> expect(
      :system_status,
      fn _ ->
        {:ok,
         %Binance.SystemStatus{
           status: 0,
           msg: "normal"
         }}
      end
    )

    assert Adapter.system_status() ==
             %XestBinance.Exchange.Status{message: "normal", status: 0}
  end

  test "provides servertime" do
    udt = ~U[2021-02-18 08:53:32.313Z]

    Adapter.Mock
    |> expect(
      :servertime,
      fn _ ->
        {:ok, udt}
      end
    )

    assert Adapter.servertime() == %XestBinance.Exchange.ServerTime{servertime: udt}
  end
end

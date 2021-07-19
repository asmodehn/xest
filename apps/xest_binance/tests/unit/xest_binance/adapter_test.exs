defmodule XestBinance.Adapter.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  #  alias Xest.ShadowClock

  alias XestBinance.Adapter

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!
  setup :with_client

  defp with_client(_) do
    cl =
      Adapter.client(nil, nil)
      |> Adapter.Client.with_adapter(Adapter.Mock.Adapter)

    %{client: cl}
  end

  test "provides system status", %{client: client} do
    Adapter.Mock.Adapter
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

    assert Adapter.system_status(client) ==
             %XestBinance.Exchange.Status{message: "normal", status: 0}
  end

  test "provides servertime", %{client: client} do
    udt = ~U[2021-02-18 08:53:32.313Z]

    Adapter.Mock.Adapter
    |> expect(
      :servertime,
      fn _ ->
        {:ok, udt}
      end
    )

    assert Adapter.servertime(client) == %XestBinance.Exchange.ServerTime{servertime: udt}
  end
end

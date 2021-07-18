defmodule XestKraken.Adapter.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  #  alias Xest.ShadowClock

  alias XestKraken.Adapter

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

  test "system_status", %{client: client} do
    Adapter.Mock.Adapter
    |> expect(
      :system_status,
      fn _ ->
        {:ok,
         %{
           status: "online",
           timestamp: ~U[2021-05-31T08:50:01Z]
         }}
      end
    )

    assert Adapter.system_status(client) == %XestKraken.Exchange.Status{
             status: "online",
             timestamp: ~U[2021-05-31T08:50:01Z]
           }
  end

  test "servertime", %{client: client} do
    Adapter.Mock.Adapter
    |> expect(
      :servertime,
      fn _ ->
        {:ok,
         %{
           unixtime: ~U[2021-05-31T08:50:01Z],
           rfc1123: "some string for this date..."
         }}
      end
    )

    assert Adapter.servertime(client) == %XestKraken.Exchange.ServerTime{
             unixtime: ~U[2021-05-31T08:50:01Z],
             rfc1123: "some string for this date..."
           }
  end
end

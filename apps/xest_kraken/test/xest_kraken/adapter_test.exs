defmodule XestKraken.Adapter.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  #  alias Xest.ShadowClock

  alias XestKraken.Adapter

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  setup do
    previous_adapter = Application.get_env(:xest_kraken, :adapter)
    Application.put_env(:xest_kraken, :adapter, XestKraken.Adapter.Mock)

    on_exit(fn ->
      # restoring config
      Application.put_env(:xest_kraken, :adapter, previous_adapter)
    end)
  end

  test "system_status" do
    Adapter.Mock
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

    assert Adapter.system_status() == %XestKraken.Exchange.Status{
             status: "online",
             timestamp: ~U[2021-05-31T08:50:01Z]
           }
  end

  test "servertime" do
    Adapter.Mock
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

    assert Adapter.servertime() == %XestKraken.Exchange.ServerTime{
             unixtime: ~U[2021-05-31T08:50:01Z],
             rfc1123: "some string for this date..."
           }
  end
end

defmodule Xest.Exchange.Adapter.Test do
  use ExUnit.Case, async: true

  import Hammox

  @time_stop ~U[2021-02-18 08:53:32.313Z]

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "retrieve status" do
    XestKraken.Exchange.Mock
    |> expect(:status, fn ->
      %XestKraken.Exchange.Status{status: "online", timestamp: @time_stop}
    end)

    %Xest.Exchange.Status{status: status, description: desc} =
      Xest.Exchange.Adapter.retrieve(:kraken, :status)

    assert status == :online
    assert desc == "online"
  end

  #  test "retrieve servertime OK", %{exg_pid: exg_pid} do
  #    ServerBehaviourMock
  #    |> expect(:time!, fn _ -> @time_stop end)
  #
  #    clock = Exchange.servertime(exg_pid)
  #    assert %ShadowClock{} = clock
  #    assert ShadowClock.now(clock) == @time_stop
  #  end
  #
end

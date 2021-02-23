defmodule Xest.Binance.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Binance

  alias Xest.Binance.ApiMock

  import Tesla.Mock

  setup do
    mock(&ApiMock.apimock/1)
    :ok
  end

  test "system status OK" do
    assert Binance.system_status() == %{"msg" => "normal", "status" => 0}
  end

  test "ping OK" do
    assert Binance.ping() == %{}
  end

  test "time OK" do
    assert Binance.time() == %{"serverTime" => 1_613_638_412_313}
  end

  # TODO : verify tesla behavior with mox expectations: https://hexdocs.pm/mox/Mox.html#expect/4-examples
end

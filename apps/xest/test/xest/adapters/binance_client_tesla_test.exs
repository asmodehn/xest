defmodule Xest.BinanceClientTesla.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.BinanceClientTesla

  alias Xest.BinanceRestApiMock

  # TODO : use Tesla.Mock.json and Mox for this cf https://github.com/teamon/tesla/issues/241
  import Tesla.Mock

  # TODO : use hammox to verify we conform to the behaviour...

  setup do
    mock(&BinanceRestApiMock.apimock/1)
    :ok
  end

  test "system status OK" do
    assert BinanceClientTesla.system_status() == {:ok ,%{"msg" => "normal", "status" => 0}}
  end

  test "ping OK" do
    assert BinanceClientTesla.ping() == {:ok, %{}}
  end

  test "time OK" do
    assert BinanceClientTesla.time() == {:ok, %{"serverTime" => 1_613_638_412_313}}
  end

  # TODO : verify tesla behavior with mox expectations: https://hexdocs.pm/mox/Mox.html#expect/4-examples
end

defmodule XestBinance.ClientTesla.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias XestBinance.ClientTesla

  alias XestBinance.RestApiMock

  # TODO : use Tesla.Mock.json and Mox for this cf https://github.com/teamon/tesla/issues/241
  #        Maybe with exvcr and bypass as well...
  import Tesla.Mock

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect,
    module: XestBinance.ClientTesla,
    behaviour: XestBinance.Ports.ClientBehaviour

  setup do
    mock(&RestApiMock.apimock/1)
    :ok
  end

  test "system status OK" do
    assert ClientTesla.system_status(nil) == {:ok, %{"msg" => "normal", "status" => 0}}
  end

  test "ping OK" do
    assert ClientTesla.ping(nil) == {:ok, %{}}
  end

  test "time OK" do
    assert ClientTesla.time(nil) == {:ok, %{"serverTime" => 1_613_638_412_313}}
  end
end

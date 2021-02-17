
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
end
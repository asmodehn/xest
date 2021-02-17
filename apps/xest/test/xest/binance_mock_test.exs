defmodule Xest.Binance.ApiMock.Test do

  use ExUnit.Case, async: true
  use FlowAssertions

  defmodule TestClient do
    use Tesla

    plug Tesla.Middleware.BaseUrl, "https://api.binance.com"
    plug Tesla.Middleware.Headers, []
    plug Tesla.Middleware.JSON

  end

  alias Xest.Binance.ApiMock

  import Tesla.Mock

  setup do
    mock(&ApiMock.apimock/1)
    :ok
  end

  # Note: this has been extracted from an actual call via unit testing (no mock)...
  test "Binance status Mock OK" do
    TestClient.get("https://api.binance.com/wapi/v3/systemStatus.html")
    |> ok_content(Tesla.Env)
    |> assert_fields(%{
      url: "https://api.binance.com/wapi/v3/systemStatus.html",
      method: :get
    })
    |> assert_fields(%{
      status: 200,
      body: %{"msg" => "normal", "status" => 0}
    })
  end

end
defmodule Xest.Binance.ApiMock.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Binance.ApiMock
  alias Xest.Binance.RawClient

  import Tesla.Mock

  setup do
    mock(&ApiMock.apimock/1)
    :ok
  end

  # Note: these have been extracted from an actual call via iex (no mock)...

  test "Binance status Mock OK" do
    RawClient.get("https://api.binance.com/wapi/v3/systemStatus.html")
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

  test "Binance ping OK" do
    RawClient.get("https://api.binance.com/api/v3/ping")
    |> ok_content(Tesla.Env)
    |> assert_fields(%{
      url: "https://api.binance.com/api/v3/ping",
      method: :get
    })
    |> assert_fields(%{
      status: 200,
      body: %{}
    })
  end

  test "Binance time OK" do
    RawClient.get("https://api.binance.com/api/v3/time")
    |> ok_content(Tesla.Env)
    |> assert_fields(%{
      url: "https://api.binance.com/api/v3/time",
      method: :get
    })
    |> assert_fields(%{
      status: 200,
      body: %{"serverTime" => 1613638412313}
    })
  end

  # TODO : manual process to run the same test with the actual api...
  #  something interactive like with the assert_value package ??
end

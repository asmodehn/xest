
defmodule Xest.Binance.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Binance


#  defp proper_headers(hdrs) do
#
#    assert {"connection", "keep-alive"} in hdrs
#    assert {"content-type", "application/json;charset=UTF-8"} in hdrs
#
#  end

  test "system status OK" do

    Binance.system_status()
    |> ok_content(Tesla.Env)
    |> assert_fields(%{
      url: "https://api.binance.com/wapi/v3/systemStatus.html",
      method: :get
    })
    |> assert_fields(%{
      status: 200,
      body: %{"msg" => "normal", "status" => 0}
#      headers: TODO
    })

  end
end
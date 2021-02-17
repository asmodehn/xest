defmodule Xest.Binance.ApiMock do

  @moduledoc """
  Module defining a mock for binance API. used in automated tests.
  This is iteratively constructed by manually probing the binance api in iex

  iex(1)>  Xest.Binance.RawClient.get("https://api.binance.com/wapi/v3/systemStatus.html")
  {:ok,
  %Tesla.Env{
  ...
  }}

  """

  require Tesla.Mock

  def apimock(%{method: method, url: url})
    when method == method and url == "https://api.binance.com/wapi/v3/systemStatus.html"
    do
    %Tesla.Env{
      status: 200,
      method: method,
      url: url,
      body: %{"msg" => "normal", "status" => 0}
    }
  end

  # TODO : add more endpoints here

end

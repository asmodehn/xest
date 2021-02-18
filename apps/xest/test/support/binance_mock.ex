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

  @base_url "https://api.binance.com"

  require Tesla.Mock

  def apimock(%{method: method, url: url})
      when method == :get and url == @base_url <> "/wapi/v3/systemStatus.html" do
    %Tesla.Env{
      status: 200,
      method: method,
      url: url,
      body: %{"msg" => "normal", "status" => 0}
    }
  end

  def apimock(%{method: method, url: url})
      when method == :get and url == @base_url <> "/api/v3/ping" do
    %Tesla.Env{
      status: 200,
      method: method,
      url: url,
      body: %{}
    }
  end

  def apimock(%{method: method, url: url})
      when method == :get and url == @base_url <> "/api/v3/time" do
    %Tesla.Env{
      status: 200,
      method: method,
      url: url,
      body: %{"serverTime" => 1613638412313}
    }
  end

  # TODO : add more endpoints here
end

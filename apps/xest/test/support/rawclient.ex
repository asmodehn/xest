defmodule Xest.Binance.RawClient do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.binance.com"
  plug Tesla.Middleware.Headers, []
  plug Tesla.Middleware.JSON

  @moduledoc """
  Simple Bare Tesla client for Binance API.

  Useful to interactively discover the REST API, like so:

  iex(1)>  Xest.Binance.RawClient.get("https://api.binance.com/wapi/v3/systemStatus.html")
  {:ok,
  %Tesla.Env{
  ...
  }}

  """

end
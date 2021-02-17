defmodule Xest.Binance do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://api.binance.com"
  plug Tesla.Middleware.Headers, []
  plug Tesla.Middleware.JSON


  def system_status() do
    get("/wapi/v3/systemStatus.html")
  end

end
defmodule Xest.Binance do
  @moduledoc """
  A module managing retrieving data from binance API
  """

  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://api.binance.com")
  plug(Tesla.Middleware.Headers, [])
  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.Logger, filter_headers: [])

  # TODO : depending on real world performance we may need one of these...
  #  plug Tesla.Middleware.Timeout, timeout: 2_000
  #
  #  plug Tesla.Middleware.Retry,
  #    delay: 500,
  #    max_retries: 10,
  #    max_delay: 4_000,
  #    should_retry: fn
  #      {:ok, %{status: status}} when status in [400, 500] -> true
  #      {:ok, _} -> false
  #      {:error, _} -> true
  #    end
  #
  #  plug Tesla.Middleware.Fuse,
  #  opts: {{:standard, 2, 10_000}, {:reset, 60_000}},
  #  keep_original_error: true,
  #  should_melt: fn
  #    {:ok, %{status: status}} when status in [428, 500, 504] -> true
  #    {:ok, _} -> false
  #    {:error, _} -> true
  #  end

  def system_status() do
    {:ok, %{status: 200, body: body}} = get("/wapi/v3/systemStatus.html")
    body
  end

  def ping() do
    {:ok, %{status: 200, body: body}} = get("/api/v3/ping")
    body
  end

  def time() do
    {:ok, %{status: 200, body: body}} = get("/api/v3/time")
    body
  end
end

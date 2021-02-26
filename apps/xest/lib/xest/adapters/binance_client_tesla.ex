defmodule Xest.BinanceClientTesla do
  @moduledoc """
  A module managing retrieving data from binance API
  """
  @behaviour Xest.Ports.BinanceClientBehaviour

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

  # TODO : rate limiter with https://hexdocs.pm/hammer

  @impl true
  def system_status() do
    case get("/wapi/v3/systemStatus.html") do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      tesla_env -> {:error, tesla_env}
    end
  end

  @impl true
  def ping() do
    case get("/api/v3/ping") do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      tesla_env -> {:error, tesla_env}
    end
  end

  @impl true
  def time() do
    case get("/api/v3/time") do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      tesla_env -> {:error, tesla_env}
    end
  end

  # TODO : register as behaviour implementation , and check with hammock...
end

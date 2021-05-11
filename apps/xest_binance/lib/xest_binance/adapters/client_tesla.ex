defmodule XestBinance.ClientTesla do
  @moduledoc """
  A module managing retrieving data from binance API
  """
  @behaviour XestBinance.Ports.ClientBehaviour

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

  # TODO : a cleaner way (middleware ? adapter in context?) to report request being sent to pubsub

  @request_topic "binance:requests"

  def subscribe(_) do
    # Phoenix.PubSub.subscribe(Xest.PubSub, @request_topic)
  end

  @impl true
  def system_status() do
    # Phoenix.PubSub.broadcast_from!(Xest.PubSub,self(), @request_topic, :system_status)
    case get("/wapi/v3/systemStatus.html") do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      tesla_env -> {:error, tesla_env}
    end
  end

  @impl true
  def ping() do
    # Phoenix.PubSub.broadcast_from!(Xest.PubSub, self(), @request_topic, :ping)
    case get("/api/v3/ping") do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      tesla_env -> {:error, tesla_env}
    end
  end

  @impl true
  def time() do
    # Phoenix.PubSub.broadcast_from!(Xest.PubSub, self(),@request_topic, :time)
    case get("/api/v3/time") do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      tesla_env -> {:error, tesla_env}
    end
  end

  # TODO : register as behaviour implementation , and check with hammock...
end

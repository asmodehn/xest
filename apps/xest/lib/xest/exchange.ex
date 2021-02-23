defmodule Xest.BinanceExchange do
  @moduledoc """
  An Agent attempting to maintain a consistent view (as state) of the exchange
  It holds the knowledge of this system regarding binance.
  """
  defstruct [
    url: "http://api.binance.com",
    status_message: "Unknown",
    status_code: -1,
    server_time_skew: 0
  ]

  alias Xest.Binance

  use Agent  # Note the agent should be unique
  # -> we can use the module name as a default to identify it

  def start_link(opts) do
    # starting the agent by passing the struct as initial value
    Agent.start_link(fn -> %Xest.BinanceExchange{
     } end, opts)
  end

  def status_retrieve(exchange) do
    %{"msg" => msg, "status" => status} = Binance.system_status()
    :ok = Agent.update(exchange, fn state -> %{state | status_message: msg, status_code: status} end)
  end

  def state(exchange) do
    Agent.get(exchange, &Function.identity/1)
  end


end


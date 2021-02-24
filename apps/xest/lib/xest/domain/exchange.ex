defmodule Xest.Domain.Exchange do
  defstruct status: %{message: nil, code: nil},
            server_time_skew: nil

  def servertime(exchange, utc_now \\ &DateTime.utc_now/0) do
    sec_skew = Time.to_seconds_after_midnight(exchange.server_time_skew)
    utc_now.()
    |> DateTime.add(elem(sec_skew, 0), :second)
    |> DateTime.add(elem(sec_skew, 1), :microsecond)

  end

  def status(exchange) do
    exchange.status
  end

end

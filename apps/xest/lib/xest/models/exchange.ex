defmodule Xest.Models.ExchangeStatus do
  use Xest, :model

  require Timex

  defstruct message: nil,
            code: nil

  @type t :: %__MODULE__{
          message: String.t(),
          code: Int.t()
        }
end

defmodule Xest.Models.Exchange do
  use Xest, :model

  defstruct status: %Xest.Models.ExchangeStatus{},
            server_time_skew_usec: nil

  @type t :: %__MODULE__{
          status: Xest.Models.ExchangeStatus.t(),
          server_time_skew_usec: Time.t()
        }

  def update(exchange, update_fields \\ []) do
    # TODO : some quick dynamic type check ?
    update_fields
    |> Enum.reduce(exchange, fn {f, v}, m -> Map.replace(m, f, v) end)
  end

  # functional read|update interface (TODO: better design ?)
  def servertime(exchange, utc_now \\ &DateTime.utc_now/0) do
    Timex.add(utc_now.(), Timex.Duration.from_microseconds(exchange.server_time_skew_usec))
  end

  def compute_time_skew_usec(_exchange, server_time, utc_now \\ &DateTime.utc_now/0) do
    Timex.diff(server_time, utc_now.())
    #    # TODO : more refined algorithm for time estimation...
    #    # and maybe extract this into a service, so the model doesnt depend on Timex...
  end
end

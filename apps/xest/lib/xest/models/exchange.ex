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
            server_time_skew: nil

  @type t :: %__MODULE__{
          status: Xest.Models.ExchangeStatus.t(),
          server_time_skew: Time.t()
        }

  def update(exchange, update_fields \\ []) do
    # TODO : some quick dynamic type check ?
    update_fields
    |> Enum.reduce(exchange, fn {f, v}, m -> Map.replace(m, f, v) end)
  end

  # functional read|update interface (TODO: better design ?)
  def servertime(exchange, utc_now \\ &DateTime.utc_now/0) do
    sec_skew =
      exchange
      |> Map.get(:server_time_skew)
      |> Time.to_seconds_after_midnight()

    utc_now.()
    |> DateTime.add(elem(sec_skew, 0), :second)
    |> DateTime.add(elem(sec_skew, 1), :microsecond)
  end

  def compute_time_skew(_exchange, server_time, utc_now \\ &DateTime.utc_now/0) do
    msec_skew = Timex.diff(server_time, utc_now.())
    Timex.Duration.to_time!(Timex.Duration.from_microseconds(msec_skew))

#    # TODO : more refined algorithm for time estimation...
#    # and maybe extract this into a service ?
  end
end

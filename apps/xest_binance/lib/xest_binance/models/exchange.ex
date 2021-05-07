defmodule XestBinance.Models.ExchangeStatus do
  require Timex

  defstruct message: nil,
            code: nil

  @type t :: %__MODULE__{
          message: nil | String.t(),
          code: nil | integer()
        }
end

defmodule XestBinance.Models.Exchange do
  defstruct status: %XestBinance.Models.ExchangeStatus{}

  @type t :: %__MODULE__{
          status: XestBinance.Models.ExchangeStatus.t()
        }

  def update(exchange, update_fields \\ []) do
    # TODO : some quick dynamic type check ?
    update_fields
    |> Enum.reduce(exchange, fn {f, v}, m -> Map.replace(m, f, v) end)
  end
end

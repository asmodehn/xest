defmodule Xest.Models.ExchangeStatus do
  use Xest, :model

  require Timex

  defstruct message: nil,
            code: nil

  @type t :: %__MODULE__{
          message: nil | String.t(),
          code: nil | integer()
        }
end

defmodule Xest.Models.Exchange do
  use Xest, :model

  defstruct status: %Xest.Models.ExchangeStatus{}

  @type t :: %__MODULE__{
          status: Xest.Models.ExchangeStatus.t()
        }

  def update(exchange, update_fields \\ []) do
    # TODO : some quick dynamic type check ?
    update_fields
    |> Enum.reduce(exchange, fn {f, v}, m -> Map.replace(m, f, v) end)
  end
end

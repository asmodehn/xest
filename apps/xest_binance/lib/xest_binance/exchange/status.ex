defmodule XestBinance.Exchange.Status do
  # default to maintenance for safety
  defstruct status: 1,
            # default to epoch
            message: "maintenance"

  @typedoc "A system status data structure"
  @type t() :: %__MODULE__{
          # TODO : refine
          status: non_neg_integer() | nil,
          message: String.t() | nil
        }

  use ExConstructor

  @spec new(map(), Keyword.t()) :: %__MODULE__{}
  def new(just_map, opts \\ []) do
    super(
      just_map
      |> Map.put_new(:message, just_map.msg)
      |> Map.drop([:msg]),
      opts
    )
  end
end

# providing implementation for Xest ACL
defimpl Xest.Exchange.Status.ACL, for: XestBinance.Exchange.Status do
  def new(%XestBinance.Exchange.Status{status: status, message: message}) do
    Xest.Exchange.Status.new(
      case status do
        0 -> :online
        1 -> :maintenance
      end,
      message
    )
  end
end

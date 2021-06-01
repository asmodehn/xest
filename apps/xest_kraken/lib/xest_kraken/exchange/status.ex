defmodule XestKraken.Exchange.Status do
  @moduledoc """
  Struct for representing the current status.

  This is kraken specific, but not adapter specific.

  ```
  defstruct [:status, :timestamp]
  ```
  """

  # default to maintenance for safety
  defstruct status: "maintenance",
            # default to epoch
            timestamp: DateTime.from_unix!(0)

  @typedoc "A system status data structure"
  @type t() :: %__MODULE__{
          # TODO : refine
          status: String.t() | nil,
          timestamp: DateTime.t() | nil
        }

  use ExConstructor

  @spec new(map(), Keyword.t()) :: %__MODULE__{}
  def new(just_map, opts \\ []) do
    # converting timestamp to datetime
    {:ok, tsz, 0} = DateTime.from_iso8601(just_map["timestamp"])
    just_map = Map.put(just_map, "timestamp", tsz)

    super(just_map, opts)
  end
end

# providing implementation for Xest ACL
defimpl Xest.Exchange.Status.ACL, for: XestKraken.Exchange.Status do
  def new(%XestKraken.Exchange.Status{status: status}) do
    Xest.Exchange.Status.new(
      case status do
        "online" -> :online
        "maintenance" -> :maintenance
      end,
      status
    )
  end
end

defmodule XestKraken.Adapter.SystemStatus do
  @moduledoc """
  Struct for representing the result returned by /0/public/SystemStatus

  ```
  defstruct [:status, :timestamp]
  ```
  """

  defstruct status: "normal",
            # default to epoch
            timestamp: DateTime.from_unix!(0)

  use ExConstructor
end

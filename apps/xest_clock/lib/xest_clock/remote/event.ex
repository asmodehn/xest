defmodule XestClock.Remote.Event do
  @docmodule """
    A Remote Event, therefore not happening **at** a specific time, but **before** the response timestamp
  """

  alias XestClock.Clock

  @enforce_keys [:before, :data]
  defstruct before: nil,
            data: nil

  @typedoc "Remote.Event struct"
  @type t() :: %__MODULE__{
          # Note : these are **local** timestamps
          before: Clock.Timestamps.t(),
          data: any()
        }

  # We need to force the timestamp to be a local one here
  # The remote timestamp can be in data...
  def new(data, %Clock.Timestamps{origin: :local} = ts) do
    %__MODULE__{
      before: ts,
      data: data
    }
  end

  def new(data, %Clock.Timestamps{origin: origin}),
    do: raise(ArgumentError, message: "invalid origin: #{origin}")
end

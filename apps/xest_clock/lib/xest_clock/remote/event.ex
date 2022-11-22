defmodule XestClock.Remote.Event do
  @docmodule """
    A Remote Event, therefore not happening **at** a specific time, but **before** the response timestamp
  """

  alias XestClock.Clock

  @enforce_keys [:inside, :data]
  defstruct inside: nil,
            data: nil

  @typedoc "Remote.Event struct"
  @type t() :: %__MODULE__{
          # Note : these are **local** timestamps
          inside: Clock.Timeinterval.t(),
          data: any()
        }

  # We need to force the timestamp to be a local one here
  # The remote timestamp can be in data...
  # or exception?
  @spec new(any(), Clock.Timeinterval.t()) :: t()
  def new(data, %Clock.Timeinterval{origin: :local} = interval) do
    %__MODULE__{
      inside: interval,
      data: data
    }
  end

  def new(data, %Clock.Timeinterval{origin: somewhere}) do
    raise(ArgumentError, message: "interval for a Remote event can only be measured locally")
  end
end

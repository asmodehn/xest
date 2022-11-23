defmodule XestClock.Event.Remote do
  @docmodule """
    A Remote Event, therefore not happening **at** a specific time, but **inside** the timeinterval
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

  def new(_data, %Clock.Timeinterval{origin: _somewhere}) do
    raise(ArgumentError, message: "interval for a Remote event can only be measured locally")
  end

  def new(_data, anything_else),
    do: raise(ArgumentError, message: "#{anything_else} is not a %Clock.Timeinterval{}")

  @spec next((() -> any()), Clock.t()) :: t()
  # TODO : replace with localclock singleton...
  def next(retrieve, clock \\ Clock.new()) do
    # TODO : guarantee this happens in order ???
    now = Clock.tick(clock)
    # WARNING THIS MAY TAKE SOME TIME...
    res = retrieve.()
    then = Clock.tick(clock)
    new(res, XestClock.Clock.Timeinterval.build(now, then))
  end

  @spec stream((() -> any()), Clock.t()) :: Stream.t()
  # TODO : default to singleton local clock
  def stream(retrieve, clock \\ Clock.new()) do
    # stream of async task to retrieve remote events
    Stream.resource(
      fn -> [Task.async(fn -> next(retrieve, clock) end)] end,
      fn acc ->
        {
          [Task.await(List.last(acc, nil))],
          acc ++ [Task.async(fn -> next(retrieve, clock) end)]
        }
      end,

      # next
      # end
      fn _acc -> :done end
    )
  end
end

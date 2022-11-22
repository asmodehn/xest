defmodule XestClock.Event.Local do
  @moduledoc """
    This module deals with the structure of an event,
    which can also be a set of events, happening in no discernable order in time nor space location.

  The clock used to timestamp the event is a clock at (or as close as possible to) the origin of
    the event, to minimize timing error.

  However, these events only make sense for a specific origin (the origin of the knowledge of them occuring),
  that we reference via a single atom, to keep flexibility in what the client code can use it for.

  """

  alias XestClock.Clock

  @enforce_keys [:at, :data]
  defstruct at: nil,
            data: nil

  @typedoc "Remote Event struct"
  @type t() :: %__MODULE__{
          at: integer,
          data: any()
        }

  @spec new(any(), Clock.Timestamp.t()) :: t()
  def new(data, %Clock.Timestamp{} = at) do
    %__MODULE__{data: data, at: at}
  end

  def new(_data, anything_else),
    do: raise(ArgumentError, message: "#{anything_else} is not a %Clock.Timestamp{}")

  @spec next((() -> any()), Clock.t()) :: t()
  # TODO : replace with localclock singleton...
  def next(notice, clock \\ Clock.new()) do
    # Note: precision is **not supposed to be an issue** here. correct assumption ??
    new(notice.(), Clock.tick(clock))
  end

  @spec stream((() -> any()), Clock.t()) :: Stream.t()
  # TODO : default to singleton local clock
  def stream(notice, clock \\ Clock.new()) do
    Stream.resource(
      fn -> [next(notice, clock)] end,
      fn acc ->
        {
          [List.last(acc, nil)],
          acc ++ [next(notice, clock)]
        }
      end,

      # next
      # end
      fn _acc -> :done end
    )
  end
end

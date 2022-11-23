defmodule XestClock.Record.Sync do
  @docmodule """
  The `XestClock.Record.Sync` module deals with a sequence of synchronous events.
  For simplicity, there is an "exact" time that is recorded with the event.

  This is intuitive and useful when the event is triggered (or observed)
  and recorded in close proximity (in the same process).

  When the event is more "large scale" and likely to involve multiple processes, it is
  more accurate to use an ASync Record as it will record a complete time interval for the event.

  """

  @enforce_keys [:clock]
  defstruct clock: nil,
            events: []

  @typedoc "XestClock.Remote.Clock struct"
  @type t() :: %__MODULE__{
          clock: XestClock.Clock.Local.t(),
          # TODO : limit size ??
          events: [XestClock.Event.Local.t()]
        }

  @spec new(XestClock.Clock.t()) :: t()
  def new(%XestClock.Clock{} = clock) do
    %__MODULE__{
      clock: clock
    }
  end

  @spec track(t(), (() -> any())) :: t()
  def track(record, effectful) do
    event = Event.new(effectful.(), XestClock.Clock.tick(record.clock))

    record
    |> Map.get_and_update(:events, event)
  end

  #  @spec record(t(), Stream.t()):: t()
  #  def record(stream, record) do
  #    stream
  #    |> Stream.into(stream, record.events, fn v -> Event.new(v, Clock.tick(record.clock)) end)
  #  end
  # TODO : stream

  defimpl Collectable, for: __MODULE__ do
    def into(sync_record) do
      collector_fun = fn
        sync_record_acc, {:cont, elem} ->
          event = XestClock.Event.Local.new(elem, XestClock.Clock.tick(sync_record_acc.clock))
          Map.update!(sync_record_acc, :events, &(&1 ++ [event]))

        sync_record_acc, :done ->
          sync_record_acc

        _sync_record_acc, :halt ->
          :ok
      end

      initial_acc = sync_record

      {initial_acc, collector_fun}
    end
  end
end

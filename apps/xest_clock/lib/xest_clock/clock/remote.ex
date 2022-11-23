defmodule XestClock.Remote.Clock do
  @docmodule """
  The `XestClock.Remote.Clock` module provides a struct representing the known remote clock,
  and functions to extract useful information from it.

  The `XestClock.Remote.Clock` module also provides similar functionality as Elixir's core `System` module,
  except it is aimed as simulating a remote system locally, and can only expose
  what is knowable about the remote (non-BEAM) system. Currently this is limited to Time functionality.

  Therefore it makes explicit the side effect of retrieving data from a specific location (clock),
  to allow as many as necessary in client code.
  Because they may not match timezones, precision must be off, NTP setup might not be correct, etc.
  we work with raw values (which may be in different units...)

  ## Time

  The `System` module also provides functions that work with time,
  returning different times kept by the **remote** system with support for
  different time units.

  One of the complexities in relying on system times is that they
  may be adjusted. See Elixir's core System for more details about this.
  One of the requirements to deal with remote systems, is that the local representation of
  a remote time data, must be mergeable with more recent data in an unambiguous way
  (cf. CRDTs for amore thorough explanation).

  This means here we can only deal with monotonic time.

  Reference to synchronize local "proxy" clock with remote :
  https://www.cs.utexas.edu/users/lorenzo/corsi/cs380d/papers/Cristian.pdf

  """

  require XestClock.Clock
  alias XestClock.Remote

  @enforce_keys [:origin, :unit, :next_tick]
  defstruct origin: nil,
            unit: nil,
            next_tick: nil

  @typedoc "XestClock.Remote.Clock struct"
  @type t() :: %__MODULE__{
          origin: atom(),
          unit: System.time_unit(),
          # next tick does(not) time it with local clock ?
          next_tick: (() -> Timestamps.t())
        }

  # Note : retrieve returns the event when received ; with a local timestamp
  @spec new(atom(), System.time_unit(), (() -> integer)) :: t()
  @spec new(atom(), System.time_unit(), (() -> integer), [Remote.Event.t()]) :: t()
  def new(origin, unit, retrieve, ticks \\ []) do
    # delegate to the basic clock structure,
    # but embeds a task for the long running request
    %__MODULE__{
      origin: origin,
      unit: XestClock.Clock.Timeunit.normalize(unit),
      next_tick: fn -> Task.async(retrieve) end
    }
  end

  # TODO in module or in strucutre ????
  #
  #  @spec retrieve_tick(t(), ( () -> XestClock.Clock.Timestamps.t())) :: Remote.Clock.t()
  #  def retrieve_tick(%__MODULE__{} = clock) do
  #    lclock = Clock.new(:local, :millisecond)
  #    req_time = lclock.tick()
  #    resp = clock.read.()
  #    resp_time = lclock.tick()
  #    offset = resp_time - req_time
  #    # KISS for now, only one offset with local.
  #    %Remote.Clock{origin: clock.origin,
  #                          unit: clock.unit,
  #                       read: clock.read,
  #                    offset: offset
  #    }
  #  end
  #
  #
  #  # a synchronous REMOTE tick
  #  @spec tick(t()) :: Remote.Event.t()
  #  def tick(%__MODULE__{} = clock, unit) do
  #    unit = normalize_time_unit(unit)
  #    lclock = Clock.new(:local, :millisecond)
  #    tick_request_ts = lclock.tick()
  #    remote_tick = Task.await(clock.retrieve.())  # immediate, blocking call...
  #
  #    %Remote.Event{before: lclock.tick(), event: remote_tick}
  #
  #  end

  #
  #  @doc """
  #  Returns the current monotonic time in the given time unit.
  #  Note the usual System's `:native` unit is not known for a remote systems,
  #  and is therefore not usable here.
  #  This time is monotonically increasing and starts in an unspecified
  #  point in time.
  #  """
  #  # TODO : this should probably be in a protocol...
  #  @spec monotonic_time(t(), System.time_unit()) :: integer
  #  def monotonic_time(%__MODULE__{} = clock, unit) do
  #    unit = normalize_time_unit(unit)
  #    lclock = Clock.new(:local, :millisecond)
  #    tick_request = lclock.tick()
  #    t = tick(clock)
  #    System.convert_time_unit(t., clock.unit, unit)
  #  end
end

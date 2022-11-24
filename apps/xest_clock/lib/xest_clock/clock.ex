defmodule XestClock.Clock do
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

  """

  alias XestClock.Clock.Timestamp
  alias XestClock.Clock.Timeunit

  @enforce_keys [:unit, :read, :origin]
  defstruct unit: nil,
            read: nil,
            origin: nil

  @typedoc "XestClock.Clock struct"
  @type t() :: %__MODULE__{
          unit: System.time_unit(),
          read: (() -> integer),
          origin: atom
        }

  @spec new(atom, System.time_unit()) :: t()
  def new(origin, unit) do
    unit = Timeunit.normalize(unit)

    %__MODULE__{
      unit: unit,
      origin: origin,
      read: fn -> System.monotonic_time(unit) end
    }
  end

  @spec new(atom, System.time_unit(), (() -> integer)) :: t()
  def new(origin, unit, read) do
    %__MODULE__{
      unit: Timeunit.normalize(unit),
      origin: origin,
      read: read
    }
  end

  def tick(%__MODULE__{} = clock) do
    Timestamp.new(clock.origin, clock.unit, clock.read.())
  end

  #  @doc """
  #  Initializes a remote clock, by specifying the unit in which the time value will be expressed
  #  Use the stream interface to record future ticks
  #  """
  #  @spec new(Stream.t(), System.time_unit()) :: t()
  #  def new(stream, unit) do
  #    # TODO : maybe this should be external, as stream creation will depend on concrete implementation
  #    # Therefore the clock here is too simple...
  #    #  stream = Stream.resource(
  #    #        fn -> [Task.async(clock_retrieve.())] end,
  #    #        # Note : we want the next clock retrieve to happen as early as possible
  #    #        # but we need to wait for a response before requesting the next one...
  #    #        fn acc ->
  #    #        acc = List.update_at(acc, -1, fn l -> Task.await(l) end)
  #    #        {[acc.last()], acc ++ [Task.async(clock_retrieve.())]}
  #    #        end,  # this lasts for ever, and to keep this simple,
  #    ##       errors should be handled in the clock_retrieve closure.
  #    #        fn acc -> :done end
  #    #      )
  #
  #    %__MODULE__{
  #      unit: unit,
  #      ticks: stream
  #    }
  #  end

  @doc """
  Returns the current monotonic time in the given time unit.
  Note the usual System's `:native` unit is not known for a remote systems,
  and is therefore not usable here.
  This time is monotonically increasing and starts in an unspecified
  point in time.
  """
  # TODO : this should probably be in a protocol...
  @spec monotonic_time(t()) :: integer
  def monotonic_time(%__MODULE__{} = clock) do
    clock.read.()
  end

  @spec monotonic_time(t(), System.time_unit()) :: integer
  def monotonic_time(%__MODULE__{} = clock, unit) do
    unit = Timeunit.normalize(unit)
    Timeunit.convert(clock.read.(), clock.unit, unit)
  end

  # TODO : this should probably be in a protocol...
  def stream(%__MODULE__{} = clock, unit) do
    # TODO or maybe just Stream.repeatedly() ??
    Stream.resource(
      # start by reading (to not have an empty stream)
      fn -> [clock.read.()] end,
      fn acc ->
        {
          [Timeunit.convert(List.last(acc), clock.unit, unit)],
          acc ++ [clock.read.()]
        }
      end,

      # next
      # end
      fn _acc -> :done end
    )
  end

  #
  #  defimpl Enumerable, for: XestClock.Clock do
  #    # CAREFUL we only care about integer stream here...
  #    @type element :: integer
  #
  #    @doc """
  #    Reduces the `XestClock.Clock` into an element.
  #    Here `reduce/3` is delegated to the stream of ticks.
  #    """
  #    @spec reduce(XestClock.Clock.t(), Enumerable.acc(), Enumerable.reducer()) ::
  #            Enumerable.result()
  #    def reduce(%XestClock.Clock{ticks: stream}, acc, reducer),
  #      do: Enumerable.reduce(stream, acc, reducer)
  #  end
end

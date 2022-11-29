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
            # TODO: get rid of this ? makes sens only when comparing many of them...
            origin: nil,
            last: nil

  @typedoc "XestClock.Clock struct"
  @type t() :: %__MODULE__{
          unit: System.time_unit(),
          read: (() -> integer) | Enumerable.t(),
          origin: atom,
          last: integer | nil
        }

  @doc """
    Creates a new clock struct that will repeatedly call System.monotonic_time
  """
  @spec new(atom, System.time_unit()) :: t()
  def new(:local, unit) do
    unit = Timeunit.normalize(unit)
    new(:local, unit, fn -> System.monotonic_time(unit) end)
  end

  @doc """
    Creates a new clock struct that will
      - repeatedly call read() if it is a function.
      - unfold the list of integers if it is a list, returning one at a time on each tick().
    read() output is dynamically verified to be ascending monotonically.
    However, in the dynamic read() case, note that the first read happens immediately on creation
    in order to get a first accumulator to compare the next with.
  """
  @spec new(atom, System.time_unit(), (() -> integer)) :: t()
  def new(origin, unit, read) when is_function(read, 0) do
    #    last_max = read.()
    %__MODULE__{
      unit: Timeunit.normalize(unit),
      origin: origin,
      read: read
    }
  end

  @spec new(atom, System.time_unit(), [integer]) :: t()
  def new(origin, unit, read) when is_list(read) do
    %__MODULE__{
      unit: Timeunit.normalize(unit),
      origin: origin,
      # TODO : is sorting before hand better ?? different behavior from repeated calls -> lazy impose skipping...
      read: read
    }
  end

  @doc """
    This is not aimed for principal use, but it is useful to have during lazy enumeration,
    to replace the last tick.
  """
  def with_last(%__MODULE__{} = clock, l) do
    %__MODULE__{
      unit: clock.unit,
      origin: clock.origin,
      read: clock.read,
      last: l
    }
  end

  @doc """
    This is not aimed for principal use. but it is useful to have for preplanned clocks,
    to iterate on the list of ticks
  """
  def with_read(%__MODULE__{} = clock, new_read) when is_list(new_read) do
    %__MODULE__{
      unit: clock.unit,
      origin: clock.origin,
      read: new_read
    }
  end

  def with_read(%__MODULE__{} = clock, new_read),
    do: raise(ArgumentError, message: "#{new_read} is not a non-empty list. unsupported.")

  @doc """
    Implements the enumerable protocol for a clock, so that it can be used as a `Stream` (lazy enumerable).
  """
  defimpl Enumerable, for: __MODULE__ do
    def count(_clock), do: {:error, __MODULE__}

    def member?(_clock, _value), do: {:error, __MODULE__}

    def slice(_clock), do: {:error, __MODULE__}

    def reduce(_clock, {:halt, acc}, _fun), do: {:halted, acc}
    def reduce(clock, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(clock, &1, fun)}

    defp timestamp(clock, read_value), do: Timestamp.new(clock.origin, clock.unit, read_value)

    def reduce(%XestClock.Clock{read: read} = clock, {:cont, acc}, fun) when is_function(read) do
      IO.inspect(clock)
      # get next tick.
      tick = read.()
      # TODO : on error stop

      # verify increasing monotonicity with acc
      # TODO : make read() or list the same reduce implementation, somehow...
      # TODO : then use Task.async to make the request asynchronous ??
      #        or separate specific reduce for remote clocks ??
      cond do
        is_integer(clock.last) and
            tick < clock.last ->
          reduce(clock, {:halt, acc}, fun)

        true ->
          reduce(
            clock
            |> XestClock.Clock.with_last(tick),
            fun.(timestamp(clock, tick), acc),
            fun
          )
      end
    end

    def reduce(%XestClock.Clock{read: []} = clock, {:cont, acc}, fun), do: {:done, acc}

    def reduce(%XestClock.Clock{read: [tick | t]} = clock, {:cont, acc}, fun) do
      IO.inspect(clock)

      # verify increasing monotonicity with acc
      cond do
        is_integer(clock.last) and
            tick < clock.last ->
          reduce(clock, {:halt, acc}, fun)

        true ->
          reduce(
            clock
            |> XestClock.Clock.with_read(t)
            |> XestClock.Clock.with_last(tick),
            fun.(timestamp(clock, tick), acc),
            fun
          )
      end
    end
  end

  @spec stamp(t(), Enumerable.t()) :: t()
  def stamp(%__MODULE__{} = clock, events) do
    Stream.zip(clock, events)
  end

  @doc """
    computes offset between two clocks, in the unit of the first one.
    This returns time values as a stream (is this a clock??)
  """
  @spec offset(t(), t()) :: Enumerable.t()
  def offset(%__MODULE__{} = clock, %__MODULE__{} = reference) do
    # we stamp one clock tick with the other...
    reference
    |> stamp(clock)
    |> Stream.map(fn {a, b} ->
      Timestamp.diff(a, b)
    end)
  end
end

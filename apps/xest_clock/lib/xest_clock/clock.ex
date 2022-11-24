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
          # Note: anonymous function of arity/2 can be enumerable... but nowadays Stream got a struct ??
          #
          read: Enumerable.t(),
          origin: atom
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
      #        Stream.concat(last_max, Stream.repeatedly(read))
      #            |> Stream.transform(last_max, fn i, acc ->
      #                # this dynamically verifies the list of values in the stream is monotonic
      #                if i >= acc, do: {[i], i}, else: {:halt, acc}
      #                # or halts the stream (an error has happened -> let it fail)
      #            end)
    }
  end

  @spec new(atom, System.time_unit(), [integer]) :: t()
  def new(origin, unit, read) when is_list(read) do
    %__MODULE__{
      unit: Timeunit.normalize(unit),
      origin: origin,
      # TODO : is sorting before hand better ?? different behavior from repeated calls -> lazy impose skipping...
      read: read
      #        Stream.unfold(Enum.sort(read, :asc), fn
      #        [] -> nil
      #        [h, hh| l] -> {h,
      #          cond do
      #            hh >= h -> {h, [hh | l]}
      #            hh < h -> {h, []}  # skip the non monotonic value and stops (same as the stream case)
      #          end}
      #      end)
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
    do: raise(ArgumentError, message: "#{new_read} is not a list. unsupported.")

  @doc """
    Implements the enumerable protocol for a clock, so that it can be used as a `Stream` (lazy enumerable).
  """
  defimpl Enumerable, for: __MODULE__ do
    def count(_clock), do: {:error, __MODULE__}

    def member?(_clock, _value), do: {:error, __MODULE__}

    def slice(_clock), do: {:error, __MODULE__}

    def reduce(_clock, {:halt, acc}, _fun), do: {:halted, acc}
    def reduce(clock, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(clock, &1, fun)}

    # reduce in the case of a list. Guarantees monotonicity
    #    def reduce(%XestClock.Clock{read: []} = clock, {:cont, acc}, _fun), do: {:done, acc}
    #    # Note : We use similar structure are list implementation, however semantics are different
    #    #  List : [[elem], count] But here we want  Clock : [[elem] | max]
    #    def reduce(%XestClock.Clock{read: [head | tail]}, {:cont, [elem | max] = acc}, fun) do
    #      # Here we delegate to the List implementation of reduce/3.
    #      # It helps when double checking the algorithm...
    ##      Be careful however of the semantics for the accumulator in List: [[elem], count]
    #      IO.inspect(acc)
    #      cond do
    #            # lookahead to verify increasing monotonicity.
    #            head >= max -> reduce(tail, fun.(head, [[],])), fun)
    #            # otherwise skip the non monotonic value and stops (same as the stream case)
    #            head < acc -> reduce(tail, fun.(head, acc) |> IO.inspect, fun)
    #          end
    #    end

    defp timestamp(clock, read_value), do: Timestamp.new(clock.origin, clock.unit, read_value)

    # because accumulator is not normalized between all Stream functions
    # But we want to get information from it
    defp first_in_acc(acc) when is_tuple(acc), do: elem(acc, 0)
    defp first_in_acc(acc) when is_list(acc), do: hd(acc)
    # TODO : keep adding cases when encountered
    #  we want to get the last element returned by the stream, leveraging the accumulator

    # NB : Here we **temporarily** overuse acc with extra structure, to guarantee monotonicity
    # We assume hd(hd(acc)) is the last element observed by the stream.
    # This is the case in List, and in our Record implementation.
    def reduce(%XestClock.Clock{read: read} = clock, {:cont, acc}, fun) when is_function(read) do
      #      IO.inspect(acc)
      # get next tick.
      tick = read.()

      # verify increasing monotonicity with acc
      cond do
        # first case : get the tick
        first_in_acc(acc) == [] ->
          #              IO.inspect("empty acc case")
          reduce(clock, fun.(timestamp(clock, tick), acc), fun)

        tick >= hd(first_in_acc(acc)).ts ->
          #              IO.inspect(" tick increase case")
          # Note : here we forcefully drop the previous accumulated stream element
          reduce(clock, fun.(timestamp(clock, tick), acc), fun)

        tick < hd(first_in_acc(acc)).ts ->
          #              IO.inspect("tick DECREASE case")
          reduce(clock, {:halt, acc}, fun)
      end
    end

    def reduce(%XestClock.Clock{read: []} = clock, {:cont, acc}, fun), do: {:done, acc}

    def reduce(%XestClock.Clock{read: [tick | t]} = clock, {:cont, acc}, fun) do
      #      IO.inspect(acc)

      # verify increasing monotonicity with acc
      cond do
        # first case : get the tick
        first_in_acc(acc) == [] ->
          #              IO.inspect("empty acc case")
          reduce(clock |> XestClock.Clock.with_read(t), fun.(timestamp(clock, tick), acc), fun)

        tick >= hd(first_in_acc(acc)).ts ->
          #              IO.inspect(" tick increase case")
          # Note : here we forcefully drop the previous accumulated stream element
          reduce(clock |> XestClock.Clock.with_read(t), fun.(timestamp(clock, tick), acc), fun)

        tick < hd(first_in_acc(acc)).ts ->
          #              IO.inspect("tick DECREASE case")
          reduce(clock, {:halt, acc}, fun)
      end
    end
  end

  # note: this is a stream clock : no unique tick() !
  # This would require to keep state in a process...
  # and we want to bring that up to the user-level

  #  @spec ticks(t()) :: Enumerable.t()
  #  def ticks(%__MODULE__{} = clock) do
  #    Stream.map(clock.read, fn ts -> Timestamp.new(clock.origin, clock.unit, ts) end)
  #  end

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

defmodule XestClock do
  @moduledoc """
  Documentation for `XestClock`.

  Design decisions:
    - since we want to follow a server clock from anywhere, we use NaiveDateTime, and assume it to always be UTC
      IMPORTANT: this requires hte machine running this code to be set to UTC as well!
    - since this is a "functional" library, we provide a data structure that the user can host in a process
    - all functions have an optional last argument that make explicit which remote exchange we are interested in.
    - internally, for simplicity, everything is tracked with integers, and each clock has its specific time_unit
    - NaiveDateTime and DateTime are re-implemented on top of our integer-based clock.
      There is no calendar manipulation here.
    - Maybe we need a gen_server to keep one element of a stream to work on later ones, for clock proxy offset... TBD...
  """

  alias XestClock.Clock

  @typedoc "A naive clock, callable (impure) function returning a NaiveDateTime"
  @type naive_clock() :: (() -> NaiveDateTime.t())
  @typedoc "A naive clock, callable (impure) function returning a integer"
  @type naive_integer_clock() :: (() -> integer)

  @typedoc "XestClock as a map or Clocks indexed by origin"
  @type t() :: %{atom() => Clock.t()}

  @spec local() :: t()
  @spec local(System.time_unit()) :: t()
  def local(unit \\ :nanosecond) do
    %{
      local: Clock.new(:local, unit)
    }
  end

  @spec custom(atom(), System.time_unit(), Enumerable.t()) :: t()
  def custom(origin, unit, tickstream) do
    Map.put(%{}, origin, Clock.new(origin, unit, tickstream))
  end

  @spec with_custom(t(), atom(), System.time_unit(), Enumerable.t()) :: t()
  def with_custom(xc, origin, unit, tickstream) do
    Map.put(xc, origin, Clock.new(origin, unit, tickstream))
  end

  @spec with_proxy(t(), Clock.t()) :: t()
  def with_proxy(%{local: local_clock} = xc, %Clock{} = remote) do
    offset = Clock.offset(local_clock, remote)
    Map.put(xc, remote.origin, local_clock |> Clock.add_offset(offset))
  end

  @spec with_proxy(t(), Clock.t(), atom()) :: t()
  def with_proxy(xc, %Clock{} = remote, reference_key) do
    # Note: reference key must already be in xc map
    # so we can discover it, and add it as the tick stream for the proxy.
    # Note THe original clock is ONLY USED to compute OFFSET !
    offset = Clock.offset(xc[reference_key], remote)

    Map.put(
      xc,
      remote.origin,
      xc[reference_key]
      # we need to replace the origin in the clock
      |> Map.put(:origin, remote.origin)
      |> Clock.add_offset(offset)
    )
  end

  @doc """
      convert a remote clock to a datetime, that we can locally compare with datetime.utc_now().
  CAREFUL: converting to datetime might drop precision (especially nanosecond...)
  """
  def to_datetime(xestclock, origin, monotone_time_offset \\ &System.time_offset/1) do
    Clock.to_datetime(xestclock[origin], monotone_time_offset)
  end
end

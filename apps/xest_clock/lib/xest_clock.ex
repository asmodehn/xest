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
  alias XestClock.Proxy

  @typedoc "A naive clock, callable (impure) function returning a DateTime"
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

  @spec with_proxy(t(), Clock.t()) :: t()
  def with_proxy(%{local: local_clock}, %Clock{} = remote) do
    proxy = Proxy.new(remote, local_clock)
    Map.put(%{}, remote.origin, proxy)
  end

  @doc """
      convert a remote clock to a datetime, that we can locally compare with datetime.utc_now().
  CAREFUL: converting to datetime might drop precision (especially nanosecond...)
  """
  def to_datetime(xestclock, origin, monotone_time_offset \\ &System.time_offset/1) do
    Proxy.to_datetime(xestclock[origin], monotone_time_offset)
  end
end

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
  """

  alias XestClock.Clock
  alias XestClock.Clock.Timestamp

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

  @spec remote(atom(), System.time_unit(), (() -> integer)) :: t()
  def remote(origin, unit, read) do
    Map.put(%{}, origin, Clock.new(origin, unit, read))
  end

  @doc """
      convert a remote clock to a datetime, that we can locally compare with datetime.utc_now().CAREFUL: converting to datetime might drop precision (especially nanosecond...)
  """
  def to_datetime(xestclock, origin, reference \\ :local, time_offset \\ &System.time_offset/1) do
    monotone_offset =
      xestclock[reference]
      |> Clock.offset(xestclock[origin])
      # because one time is enough to compute offset
      |> Enum.at(0)

    # we take the reference (usually :local)
    # and we add the monotone offset, as well as a the local system offset to deduce current datetime
    xestclock[reference]
    |> Stream.map(fn ref ->
      tstamp =
        Timestamp.plus(
          ref,
          Timestamp.plus(
            monotone_offset,
            Timestamp.new(
              :local_offset,
              xestclock[reference].unit,
              time_offset.(xestclock[reference].unit)
            )
          )
        )

      DateTime.from_unix!(tstamp.ts, tstamp.unit)
    end)
  end
end

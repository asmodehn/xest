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

  @typedoc "A naive clock, callable (impure) function returning a DateTime"
  @type naive_clock() :: (() -> NaiveDateTime.t())

  @typedoc "Remote NaiveDatetime struct"
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
end

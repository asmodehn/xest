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

  # module attribute to lock it on compilation.
  @system_utc_now &NaiveDateTime.utc_now/0

  @enforce_keys []
  defstruct remotes: %{},
            system_clock_closure: @system_utc_now

  @typedoc "A naive clock, callable (impure) function returning a DateTime"
  @type naive_clock() :: (() -> NaiveDateTime.t())

  @typedoc "Remote NaiveDatetime struct"
  @type t() :: %__MODULE__{
          remotes: %{atom() => RemoteClock.t()},
          system_clock_closure: naive_clock()
        }

  @doc """
  Returns the current (local or remote) naive datetime in UTC.

  To get the local time, just use the default clock:
    %XestClock{} |> XestClock.utc_now()
  But it can also be customized for tests

  ## Examples

      %XestClock{system_clock_closure: fn ->  ~N[2010-04-17 14:00:00] end} |> XestClock.utc_now()
       ~N[2010-04-17 14:00:00]

  """
  def utc_now(%XestClock{} = clock, exchange \\ :local) do
    clock.system_clock_closure.()
  end
end

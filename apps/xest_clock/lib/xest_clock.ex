defmodule XestClock do
  @moduledoc """
  Documentation for `XestClock`.

  Design decisions:
    - since we want to follow a server clock from anywhere, we use NaiveDateTime, and assume it to always be UTC
    - since this is a "functional" library, we provide a data structure that the user can host in a process
  """

  @enforce_keys []
  defstruct remotes: %{},
            system_clock_closure: &NaiveDateTime.utc_now/0

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

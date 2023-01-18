defmodule XestClock.NaiveDateTime do
  @moduledoc """
    A simple system module, with direct access to Elixir's NaiveDateTime.

    Here is explicited the difference in computation in some of the internal calculation done on time by the erlang VM.
    We need to work from the VM time (retrieved from monotonic_time) to finally get utc_now.

  We rely on the VM time eventually converging to the local time in case of time differences intra cluster.
    We base our calculations on monotonic_time to be able to handle extra-cluster clocks.
  """

  # to make sure we do not inadvertently rely on Elixir's System or DateTime
  alias XestClock.System
  alias XestClock.NewWrapper.DateTime

  @type t :: NaiveDateTime.t()

  defmodule OriginalBehaviour do
    @moduledoc """
        A small behaviour to allow mocks of some functions of interest in Elixir's `NaiveDateTime`.

        `XestClock.NaiveDateTime` relies on it as well, and provides an implementation for this behaviour.
        It acts as well as an adapter, as transparently as is necessary.
    """

    @type t :: XestClock.NaiveDateTime.t()

    @callback utc_now(Calendar.calendar()) :: t
  end

  @behaviour OriginalBehaviour

  @spec utc_now(Calendar.calendar()) :: t
  def utc_now(calendar \\ Calendar.ISO)

  def utc_now(Calendar.ISO) do
    {:ok, {year, month, day}, {hour, minute, second}, microsecond} =
      Calendar.ISO.from_unix(
        System.system_time(System.Extra.native_time_unit()),
        System.Extra.native_time_unit()
      )

    %NaiveDateTime{
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: second,
      microsecond: microsecond,
      calendar: Calendar.ISO
    }
  end

  def utc_now(calendar) do
    calendar
    |> DateTime.utc_now()
    |> DateTime.to_naive()
  end
end

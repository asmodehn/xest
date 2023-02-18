defmodule XestClock.Time do
  @moduledoc """
      A simple system module, with direct access to Elixir's System.

      This module can also be used as a point to mock system clock access for extensive testing.
  """

  # to make sure we do not inadvertently rely on Elixir's System or DateTime
  alias XestClock.System
  #  alias XestClock.Time.Extra

  @type t :: Time.t()

  #  defmodule ExtraBehaviour do
  #    @moduledoc """
  #        A small behaviour to allow mocks of native_time_unit.
  #    """
  #
  ##    @type time_unit :: XestClock.System.time_unit()
  ##
  ##    @callback native_time_unit() :: System.time_unit()
  #  end

  # These simply replicate Elixir.Time with explicit units

  @spec utc_now(Calendar.calendar()) :: t
  def utc_now(calendar \\ Calendar.ISO) do
    {:ok, _, {hour, minute, second}, microsecond} =
      System.system_time(System.native_time_unit())
      |> Calendar.ISO.from_unix(System.native_time_unit())

    iso_time = %Time{
      hour: hour,
      minute: minute,
      second: second,
      microsecond: microsecond,
      calendar: Calendar.ISO
    }

    Elixir.Time.convert!(iso_time, calendar)
  end

  #
  #  @behaviour ExtraBehaviour
  #
  #
  #  @doc false
  #  defp extra_impl,
  #    do: Application.get_env(:xest_clock, :time_extra_module, XestClock.Time.Extra)
end

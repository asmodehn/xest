defmodule XestClock.System do
  @moduledoc """
    A simple system module, with direct access to Elixir's System.

    This module can also be used as a point to mock system clock access for extensive testing.

    Here in source is explicited some of the internal calculation done on time by the erlang VM,
    starting from a monotonic_time and recovering utc_now.

    Note: os_time is unknowable from here, we work between the distributed VM and remote servers,
      not part of the managed cluster, and potentially with clocks that are not in sync.
  """

  alias XestClock.System.Extra

  @type time_unit :: System.time_unit()

  defmodule OriginalBehaviour do
    @moduledoc """
        A small behaviour to allow mocks of some functions of interest in Elixir's `System`.

        `XestClock.System` relies on it as well, and provides an implementation for this behaviour.
        It acts as well as an adapter, as transparently as is necessary.
    """

    @type time_unit :: XestClock.System.time_unit()

    @callback monotonic_time(time_unit()) :: integer()
    @callback convert_time_unit(integer, time_unit(), time_unit()) :: integer
    @callback time_offset(time_unit()) :: integer()
  end

  @doc """
      A slightly different implementation of system_time/1, using monotonic_time/1

      This system_time/1 is **not monotonic**, given we add time_offset.

      Rsults should be *similar* to the original Elixir's System.system_time/1,
      however not strictly equal. Therefore testing this is tricky and left to the user
      at least until we figure out a way to do it...

      **Note: This is an impure function.**
  """
  @spec system_time(time_unit) :: integer()
  def system_time(unit) do
    # Both monotonic_time and time_offset need to be of the same unit
    monotonic_time(unit) + time_offset(unit)
  end

  @behaviour OriginalBehaviour

  @doc """
      Monotonic time, the main way to compute with time in XestClock,
      as it protects against unexpected time shifts and guarantees ever increasing value.

  """
  @impl OriginalBehaviour
  def monotonic_time(unit) do
    impl().monotonic_time(Extra.normalize_time_unit(unit))
  end

  @doc """
  Converts `time` from time unit `from_unit` to time unit `to_unit`.
  The result is rounded via the floor function.
  Note: this `convert_time_unit/3` **does not accept** `:native`, since
  it is aimed to be used by remote clocks for which `:native` can be ambiguous.
  """
  def convert_time_unit(_time, _from_unit, :native),
    do: raise(ArgumentError, message: "convert_time_unit does not support :native unit")

  def convert_time_unit(_time, :native, _to_unit),
    do: raise(ArgumentError, message: "convert_time_unit does not support :native unit")

  @impl OriginalBehaviour
  def convert_time_unit(time, from_unit, to_unit) do
    impl().convert_time_unit(
      time,
      Extra.normalize_time_unit(from_unit),
      Extra.normalize_time_unit(to_unit)
    )
  end

  @doc """
     Used to retrieve system_time/1 from monotonic_time/1
      This is used to compute human-readable datetimes

      **Note: This is an impure function.**

  """
  @impl OriginalBehaviour
  def time_offset(unit) do
    impl().time_offset(Extra.normalize_time_unit(unit))
  end

  @doc false
  defp impl, do: Application.get_env(:xest_clock, :system_module, System)
end

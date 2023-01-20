defmodule XestClock.NewWrapper.DateTime do
  @moduledoc """
    A simple system module, with direct access to Elixir's DateTime.

    Here in source is explicited some of the internal calculation done on time by the erlang VM,
    starting from a system_time and recovering utc_now.

    Note: os_time is unknowable from here, we work between the distributed VM and remote servers,
      not part of the managed cluster, and potentially with clocks that are not in sync.
  """

  # to make sure we do not inadvertently rely on Elixir's System
  alias XestClock.System

  @type t :: DateTime.t()

  @doc """
  Reimplementation of `DateTime.utc_now/1` on top of `System.system_time/1` and `DateTime.from_unix/3`

  Therefore, this doesn't depend on Elixir's DateTime any longer, and doesn't need to be mocked.
  In fact:
    - `System.system_time/1` depends on `System.monotonic_time/1` and `System.time_offset/1` that need to be mocked for testing
    - `DateTime.from_unix/3` is pure so a stub delegating to Elixir's DateTime can be used
  """
  def utc_now(calendar \\ Calendar.ISO) do
    # We use :native unit here to get maximum precision.
    System.system_time(System.native_time_unit())
    |> from_unix!(System.native_time_unit(), calendar)
  end

  # These are pure and simply wrap Elixir.DateTime without the need for a mock

  def from_unix(integer, unit \\ :second, calendar \\ Calendar.ISO) when is_integer(integer) do
    Elixir.DateTime.from_unix(integer, System.Extra.normalize_time_unit(unit), calendar)
  end

  def from_unix!(integer, unit \\ :second, calendar \\ Calendar.ISO) do
    Elixir.DateTime.from_unix!(integer, System.Extra.normalize_time_unit(unit), calendar)
  end

  def to_naive(calendar_datetime) do
    Elixir.DateTime.to_naive(calendar_datetime)
  end
end

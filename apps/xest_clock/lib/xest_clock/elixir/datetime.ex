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

  defmodule OriginalBehaviour do
    @moduledoc """
        A small behaviour to allow mocks of some functions of interest in Elixir's `DateTime`.

        `XestClock.DateTime` relies on it as well, and provides an implementation for this behaviour.
        It acts as well as an adapter, as transparently as is necessary.
    """

    @type t :: XestClock.DateTime.t()

    @callback from_unix(integer, System.time_unit(), Calendar.calendar()) ::
                {:ok, t} | {:error, atom}
    @callback from_unix!(integer, System.time_unit(), Calendar.calendar()) :: t
    @callback to_naive(Calendar.datetime()) :: NaiveDateTime.t()
  end

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

  @behaviour OriginalBehaviour

  @impl OriginalBehaviour
  def from_unix(integer, unit \\ :second, calendar \\ Calendar.ISO) when is_integer(integer) do
    impl().from_unix(integer, System.Extra.normalize_time_unit(unit), calendar)
  end

  @impl OriginalBehaviour
  def from_unix!(integer, unit \\ :second, calendar \\ Calendar.ISO) do
    impl().from_unix!(integer, System.Extra.normalize_time_unit(unit), calendar)
  end

  @impl OriginalBehaviour
  def to_naive(calendar_datetime) do
    impl().to_naive(calendar_datetime)
  end

  @doc false
  defp impl, do: Application.get_env(:xest_clock, :datetime_module, DateTime)
end

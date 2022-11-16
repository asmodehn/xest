defmodule XestClock.Timestamps do
  @docmodule """
  The `XestClock.Timestamps` module deals with (possibly lists of) timestamps.
  However the unit must be consistent on all timestamps, and functions here enforce it.

  It should always be embedded in a structure making the locality explicit, as time measurement
  doesn't make any sense without a place of that time measurement.

  Therefore managing the place of measurement is left to the client code.
  """

  @enforce_keys [:unit]
  defstruct timestamps: [],
            unit: nil

  @typedoc "Timestamps struct"
  @type t() :: %__MODULE__{
          timestamps: [integer()],
          unit: System.time_unit()
        }

  @doc """
    Creating the timestamp
  """
  @spec new(System.time_unit()) :: t()
  def new(unit) do
    normalize_time_unit(unit)
    %__MODULE__{unit: unit}
  end

  #  @spec stamp(t(), integer(), System.time_unit()) :: t()
  #  def stamp(stamps, time, unit) when unit == stamps.unit do
  #    Map.get_and_update(stamps, :timestamps, fn ts -> ts ++ [time] end)
  #  end

  ## Duplicated from https://github.com/elixir-lang/elixir/blob/0909940b04a3e22c9ea4fedafa2aac349717011c/lib/elixir/lib/system.ex#L1344
  defp normalize_time_unit(:second), do: :second
  defp normalize_time_unit(:millisecond), do: :millisecond
  defp normalize_time_unit(:microsecond), do: :microsecond
  defp normalize_time_unit(:nanosecond), do: :nanosecond

  defp normalize_time_unit(other) do
    raise ArgumentError,
          "unsupported time unit. Expected :second, :millisecond, " <>
            ":microsecond, :nanosecond, or a positive integer, " <> "got #{inspect(other)}"
  end
end

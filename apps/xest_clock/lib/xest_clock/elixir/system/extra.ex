defmodule XestClock.System.Extra do
  @moduledoc """
      This module holds Extra functionality that is needed by XestClock.System,
    but not present, or not exposed in Elixir.System
  """

  @behaviour XestClock.System.ExtraBehaviour

  @doc """
    Dynamically computes the native time unit, as per https://hexdocs.pm/elixir/1.13.4/System.html#convert_time_unit/3
    In order to cache this value and avoid recomputation, a local clock server can be used.
  """
  @impl XestClock.System.ExtraBehaviour
  def native_time_unit() do
    # Special usecase: Explicit call to elixir
    case Elixir.System.convert_time_unit(1, :second, :native) do
      # Handling special cases
      1 -> :second
      1_000 -> :millisecond
      1_000_000 -> :microsecond
      1_000_000_000 -> :nanosecond
      # Defaults to parts per second, as per https://hexdocs.pm/elixir/1.13.4/System.html#t:time_unit/0
      parts_per_second -> parts_per_second
    end
  end

  @doc """
    Normalizes time_unit, just like internal Elixir's System.normalize

  The main difference is that it does **not** accept :native, as it is a local-specific unit
   and makes no sense on a distributed time architecture.
  """
  def normalize_time_unit(:second), do: :second
  def normalize_time_unit(:millisecond), do: :millisecond
  def normalize_time_unit(:microsecond), do: :microsecond
  def normalize_time_unit(:nanosecond), do: :nanosecond

  def normalize_time_unit(unit) when is_integer(unit) and unit > 0, do: unit

  def normalize_time_unit(other) do
    raise ArgumentError,
          "unsupported time unit. Expected :second, :millisecond, " <>
            ":microsecond, :nanosecond, or a positive integer, " <> "got #{inspect(other)}"
  end

  @doc """
    ordered by precision leveraging convert to detect precision loss
  Note the order on unit is hte opposite order than on values with those unit...
  """
  # TODO : operator ??
  def time_unit_inf(a, b) do
    # directly call the system version of convert_time_unit (pure)
    # after taking care of normalizing the time_units
    Elixir.System.convert_time_unit(1, normalize_time_unit(b), normalize_time_unit(a)) == 0
  end

  def time_unit_sup(a, b) do
    not time_unit_inf(a, b) and a != b
  end
end

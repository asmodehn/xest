defmodule XestClock.Clock.Timeunit do
  ## Duplicated from https://github.com/elixir-lang/elixir/blob/0909940b04a3e22c9ea4fedafa2aac349717011c/lib/elixir/lib/system.ex#L1344
  def normalize(:second), do: :second
  def normalize(:millisecond), do: :millisecond
  def normalize(:microsecond), do: :microsecond
  def normalize(:nanosecond), do: :nanosecond

  def normalize(other) do
    raise ArgumentError,
          "unsupported time unit. Expected :second, :millisecond, " <>
            ":microsecond, :nanosecond, or a positive integer, " <> "got #{inspect(other)}"
  end

  @doc """
  Converts `time` from time unit `from_unit` to time unit `to_unit`.
  The result is rounded via the floor function.
  Note: this `convert_time_unit/3` **does not accept** `:native`, since
  it is aimed to be used by remote clocks for which `:native` can be ambiguous.
  """
  @spec convert(integer, System.time_unit(), System.time_unit()) :: integer
  def convert(_time, _from_unit, :native),
    do: raise(ArgumentError, message: "convert_time_unit does not support :native unit")

  def convert(_time, :native, _to_unit),
    do: raise(ArgumentError, message: "convert_time_unit does not support :native unit")

  defdelegate convert_time_unit(time, from_unit, to_unit), to: System
end

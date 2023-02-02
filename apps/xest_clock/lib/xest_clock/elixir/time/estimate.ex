defmodule XestClock.Time.Estimate do
  @moduledoc """
  This module holds time estimates.
  It is use for implicit conversion and managing errors when doing time arithmetic
  """

  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System

  alias XestClock.Time
  alias XestClock.Stream.Timed

  @enforce_keys [:unit, :value]
  defstruct unit: nil,
            value: nil,
            # TODO : maybe should be just a timevalue ?
            error: nil

  @typedoc "TimeValue struct"
  @type t() :: %__MODULE__{
          unit: System.time_unit(),
          value: integer(),
          # TODO : maybe should be just a timevalue ?
          error: integer()
        }

  def new(%Time.Value{} = tv, %Timed.LocalDelta{} = ld) do
    # TODO : shouldn't this conversion be reversed ?? impact on error ??
    without_skew = tv.value + Time.Value.convert(ld.offset, tv.unit).value
    # with_skew = tv.value + System.convert_time_unit(ld.offset, ld.unit, tv.unit) * ld.skew

    %__MODULE__{
      unit: tv.unit,
      value: without_skew,
      # == without_skew - with_skew
      error: Time.Value.convert(ld.offset, tv.unit).value * (1.0 - ld.skew)
    }
  end
end

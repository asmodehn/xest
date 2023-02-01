defmodule XestClock.Stream.Time.LocalDelta do
  @moduledoc """
      A module to manage the difference between the local timestamps and a remote timestamps,
      and safely compute with it as a specific time value
    skew is added to keep track of the derivative over time...
  """

  alias XestClock.Time

  @enforce_keys [:offset]
  defstruct offset: nil,
            skew: nil

  @typedoc "XestClock.Timestamp struct"
  @type t() :: %__MODULE__{
          offset: Time.Value.t(),
          # note skew is unit-less
          skew: float()
        }

  @doc """
      builds a delta value from values inside a timestamp and a local timestamp
  """
  def new(%Time.Stamp{} = ts, %XestClock.Stream.Timed.LocalStamp{} = lts) do
    # convert to the stamp unit (higher local precision is not meaningful for the result)
    converted_lts = Time.Value.convert(lts.monotonic, ts.ts.unit)

    %__MODULE__{
      offset: Time.Value.new(ts.ts.unit, Time.Value.diff(ts.ts, converted_lts))
    }
  end

  def new(
        %Time.Stamp{} = ts,
        %XestClock.Stream.Timed.LocalStamp{} = lts,
        %__MODULE__{} = previous_delta
      ) do
    new_delta = new(ts, lts)

    # convert to the recent time_unit
    converted_previous_offset = Time.Value.convert(previous_delta.offset, new_delta.offset.unit)

    skew = new_delta.offset / converted_previous_offset

    # TODO : is there any point to get longer skew list over time ??
    # if not, how to prove it ?

    %{new_delta | skew: skew}
  end
end

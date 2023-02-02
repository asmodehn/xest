defmodule XestClock.Stream.Timed.LocalDelta do
  @moduledoc """
      A module to manage the difference between the local timestamps and a remote timestamps,
      and safely compute with it as a specific time value
    skew is added to keep track of the derivative over time...
  """

  alias XestClock.Time

  alias XestClock.Stream.Timed

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
  def new(%Time.Stamp{} = ts, %Timed.LocalStamp{} = lts) do
    # convert to the stamp unit (higher local precision is not meaningful for the result)
    converted_lts = Time.Value.convert(lts.monotonic, ts.ts.unit)

    %__MODULE__{
      offset: Time.Value.diff(ts.ts, converted_lts)
    }
  end

  def with_previous(
        %__MODULE__{} = current,
        %__MODULE__{} = previous
      )
      when current.offset.unit == previous.offset.unit do
    skew =
      if previous.offset.value == 0 do
        nil
      else
        current.offset.value / previous.offset.value
      end

    # TODO : is there any point to get longer skew list over time ??
    # if not, how to prove it ?

    %{current | skew: skew}
  end

  def compute(enum) do
    Stream.transform(enum, nil, fn
      {%Time.Stamp{} = ts, %Timed.LocalStamp{} = lts}, nil ->
        delta = new(ts, lts)
        {[{ts, lts, delta}], delta}

      {%Time.Stamp{} = ts, %Timed.LocalStamp{} = lts}, %__MODULE__{} = previous_delta ->
        delta = new(ts, lts) |> with_previous(previous_delta)
        {[{ts, lts, delta}], delta}
    end)
  end
end

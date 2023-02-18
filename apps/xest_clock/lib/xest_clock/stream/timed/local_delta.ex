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
          skew: float() | nil
        }

  @doc """
      builds a delta value from values inside a timestamp and a local timestamp
  """
  def new(%Time.Value{} = tv, %Timed.LocalStamp{} = lts) do
    # CAREFUL! we should only take monotonic component in account.
    # Therefore the offset might be bigger than naively expected (vm_offset is not taken into account).
    converted_monotonic_lts = Timed.LocalStamp.monotonic_time(lts)

    %__MODULE__{
      offset: Time.Value.diff(tv, converted_monotonic_lts)
    }
  end

  def compute(enum) do
    Stream.transform(enum, nil, fn
      {%Time.Value{} = tv, %Timed.LocalStamp{} = lts}, nil ->
        delta = new(tv, lts)
        {[{tv, lts, delta}], {delta, lts}}

      {%Time.Value{} = tv, %Timed.LocalStamp{} = lts},
      {%__MODULE__{} = previous_delta, %Timed.LocalStamp{} = previous_lts} ->
        # TODO: wait... is this a scan ???
        local_time_delta = Timed.LocalStamp.elapsed_since(lts, previous_lts)
        delta_without_skew = new(tv, lts)

        skew =
          if local_time_delta.value == 0 do
            # special case where no time passed between the two timestamps
            # This can happen during monotonic time correction...
            # => we reuse skew as a fallback in this (rare) case,
            # as we cannot recompute it with the information we currently have.
            previous_delta.skew
          else
            Time.Value.div(
              Time.Value.diff(delta_without_skew.offset, previous_delta.offset),
              local_time_delta
            )
          end

        delta = %{delta_without_skew | skew: skew}

        {[{tv, lts, delta}], {delta, lts}}
    end)
  end

  @spec offset(t(), Time.LocalStamp.t()) :: Time.Value.t() | nil
  def offset(%__MODULE__{} = dv, %Timed.LocalStamp{} = lts) do
    # take local time now
    lts_now = Timed.LocalStamp.now(lts.unit)
    offset_at(dv, lts, lts_now)
  end

  def offset_at(
        %__MODULE__{} = dv,
        %Timed.LocalStamp{} = _lts,
        %Timed.LocalStamp{} = _lts_now
      )
      when is_nil(dv.skew),
      do: %{dv.offset | error: nil}

  # in this case we pass an error of nil as semantics for "cannot compute"
  # as a signal for the client to update the delta struct

  def offset_at(
        %__MODULE__{} = dv,
        %Timed.LocalStamp{} = lts,
        %Timed.LocalStamp{} = lts_now
      ) do
    # determine elapsed time
    local_time_delta =
      Time.Value.diff(
        Timed.LocalStamp.as_timevalue(lts_now),
        Timed.LocalStamp.as_timevalue(lts)
      )

    # multiply with previously measured skew (we assume it didn't change on the remote...)
    adjustment = Time.Value.scale(local_time_delta, dv.skew)

    # summing while keeping maximum precision to keep estimation visible
    adjusted_offset = Time.Value.sum(dv.offset, adjustment)

    # We need to add the adjustment as error since this is an estimation based on past skew
    %{
      adjusted_offset
      | error:
          adjusted_offset.error +
            System.convert_time_unit(abs(adjustment.value), adjustment.unit, adjusted_offset.unit)
    }
  end
end

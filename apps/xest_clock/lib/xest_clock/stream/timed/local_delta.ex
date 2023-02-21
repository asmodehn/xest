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
    converted_lts = Timed.LocalStamp.system_time(lts)

    %__MODULE__{
      offset: Time.Value.diff(tv, converted_lts)
    }
  end

  def compute(enum) do
    Stream.map(enum, fn
      {%Time.Value{} = tv, %Timed.LocalStamp{} = lts, %Time.Derivatives{} = drv} ->
        # build delta from derivatives, as a transition...
        # TODO : PID integration to replace delta...
        delta = %__MODULE__{offset: drv.prop, skew: drv.derv |> elem(0)}
        {tv, lts, delta}
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
        Timed.LocalStamp.system_time(lts_now),
        Timed.LocalStamp.system_time(lts)
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

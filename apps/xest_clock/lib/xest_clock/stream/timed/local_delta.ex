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

  # WRONG
  #  def with_previous(
  #        %__MODULE__{} = current,
  #        %__MODULE__{} = previous
  #      )
  #      when current.offset.unit == previous.offset.unit do
  #    skew =
  #      if previous.offset.value == 0 do
  #        nil
  #      else
  #        current.offset.value / previous.offset.value
  #      end
  #
  #    # TODO : is there any point to get longer skew list over time ??
  #    # if not, how to prove it ?
  #
  #    %{current | skew: skew}
  #  end

  def compute(enum) do
    Stream.transform(enum, nil, fn
      {%Time.Stamp{} = ts, %Timed.LocalStamp{} = lts}, nil ->
        delta = new(ts, lts)
        {[{ts, lts, delta}], {delta, lts}}

      {%Time.Stamp{} = ts, %Timed.LocalStamp{} = lts},
      {%__MODULE__{} = previous_delta, %Timed.LocalStamp{} = previous_lts} ->
        # TODO: wait... is this a scan ???
        local_time_delta = Timed.LocalStamp.elapsed_since(lts, previous_lts)
        delta_without_skew = new(ts, lts)

        delta = %{
          delta_without_skew
          | skew:
              Time.Value.div(
                Time.Value.diff(delta_without_skew.offset, previous_delta.offset),
                local_time_delta
              )
        }

        {[{ts, lts, delta}], {delta, lts}}
    end)
  end

  def error_since(%__MODULE__{} = dv, %Timed.LocalStamp{} = lts) do
    # take local time now
    lts_now = Timed.LocalStamp.now(lts.unit)
    error_since_at(dv, lts, lts_now)
  end

  def error_since_at(
        %__MODULE__{} = dv,
        %Timed.LocalStamp{} = _lts,
        %Timed.LocalStamp{} = _lts_now
      )
      # assumes no skew -> offset constant -> no error (best effort)
      when is_nil(dv.skew),
      do: Time.Value.new(dv.offset.unit, 0)

  # TODO : maybe we should get rid of this particular nil case for skew ??
  # assumes it is 1.0 ??? 0.0 ??? offset ??? default to initial object ??

  def error_since_at(%__MODULE__{} = dv, %Timed.LocalStamp{} = lts, %Timed.LocalStamp{} = lts_now) do
    # determine elapsed time
    local_time_delta =
      Time.Value.diff(
        Timed.LocalStamp.system_time(lts_now),
        Timed.LocalStamp.system_time(lts)
      )

    # multiply with previously measured skew (we assume it didn't change on the remote...)
    Time.Value.scale(local_time_delta, dv.skew)
  end
end

defmodule XestClock.Proxy do
  @docmodule """
    This module deals with a simulated clock, wrapping the original (remote) clock.

    The simulated clock is useful to store the detected offset, to avoid recomputing it on each call.

  """

  alias XestClock.Clock
  alias XestClock.Timestamp

  # to be able to get one element in a stream to use as offset
  # TODO : Better: everything in a stream ??

  @enforce_keys [:remote, :reference]
  defstruct remote: nil,
            reference: nil,
            offset: nil

  @typedoc "XestClock.Clock struct"
  @type t() :: %__MODULE__{
          remote: Clock.t(),
          reference: Clock.t(),
          offset: Clock.Timestamp.t()
        }

  @spec new(Clock.t(), Clock.t()) :: t()
  def new(%Clock{} = clock, %Clock{} = ref) do
    # force same unit on both clock, to simplify computations later on
    cond do
      Clock.Timeunit.inf(clock.unit, ref.unit) ->
        %__MODULE__{
          remote: Clock.convert(clock, ref.unit),
          reference: ref,
          offset: Timestamp.new(clock.origin, ref.unit, 0)
        }

      Clock.Timeunit.sup(clock.unit, ref.unit) ->
        %__MODULE__{
          remote: clock,
          reference: Clock.convert(ref, clock.unit),
          offset: Timestamp.new(clock.origin, ref.unit, 0)
        }

      true ->
        %__MODULE__{
          remote: clock,
          reference: ref,
          offset: Timestamp.new(clock.origin, ref.unit, 0)
        }
    end
  end

  # TODO : remote() that is the offset, simulated version of the remote clock...
  # TODO : Make local and proxy interface converge...

  @doc """
    with_offset computes offset compared with a reference clock.
    To force recomputation, just set the offset to nil.
  """
  @spec add_offset(t(), Timestamp.t()) :: t()
  def add_offset(%__MODULE__{} = proxy, %Timestamp{} = offset) do
    %{
      proxy
      | offset: Timestamp.plus(proxy.offset, offset),

        # TODO : since we consume here one tick of the reference, the reference should be changed...
        reference: proxy.reference
    }
  end

  @spec to_datetime(t(), (System.time_unit() -> integer)) :: Enumerable.t()
  def to_datetime(%__MODULE__{} = proxy, monotone_time_offset \\ &System.time_offset/1) do
    proxy.reference
    |> Clock.as_timestamp()
    |> Stream.map(fn ref ->
      tstamp =
        Timestamp.plus(
          ref,
          Timestamp.plus(
            proxy.offset,
            Timestamp.new(
              :time_offset,
              proxy.reference.unit,
              monotone_time_offset.(proxy.reference.unit)
            )
          )
        )

      DateTime.from_unix!(tstamp.ts, tstamp.unit)
    end)
  end
end

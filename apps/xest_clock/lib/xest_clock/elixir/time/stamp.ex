defmodule XestClock.Time.Stamp do
  @moduledoc """
  The `XestClock.Clock.Time.Stamp` module deals with timestamp struct.
  This struct can store one timestamp.

  Note: time measurement doesn't make any sense without a place of that time measurement.
  Therefore there is no implicit origin conversion possible here,
  and managing the place of measurement is left to the client code.
  """

  # intentionally hiding Elixir.System
  alias XestClock.System

  alias XestClock.Time

  @enforce_keys [:origin, :ts]
  defstruct ts: nil,
            origin: nil

  @typedoc "XestClock.Timestamp struct"
  @type t() :: %__MODULE__{
          ts: Time.Value.t(),
          origin: atom()
        }

  @spec new(atom(), System.time_unit(), integer()) :: t()
  def new(origin, unit, ts) do
    nu = System.Extra.normalize_time_unit(unit)

    %__MODULE__{
      # TODO : should be an already known atom...
      origin: origin,
      # TODO : after getting rid of origin, this becomes just a time value...
      ts: Time.Value.new(nu, ts)
    }
  end

  def with_previous(%__MODULE__{} = current, %__MODULE__{} = previous)
      when current.origin == previous.origin do
    %{current | ts: current.ts |> Time.Value.with_previous(previous.ts)}
  end

  def stream(enum, origin) do
    Stream.map(enum, fn
      # special condition for localstamp to not embed it in (remote or not) timestamp
      {elem, %XestClock.Stream.Timed.LocalStamp{} = lts} ->
        {%Time.Stamp{origin: origin, ts: elem}, lts}

      elem ->
        %Time.Stamp{origin: origin, ts: elem}
    end)
  end
end

defimpl String.Chars, for: XestClock.Time.Stamp do
  def to_string(%XestClock.Time.Stamp{
        origin: origin,
        ts: tv
      }) do
    # TODO: maybe have a more systematic / global way to manage time unit ??
    # to something that is immediately parseable ? some sigil ??
    # some existing physical unit library ?

    "{#{origin}: #{tv}}"
  end
end

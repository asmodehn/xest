defmodule XestClock.TimeValue do
  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System

  @enforce_keys [:unit, :monotonic]
  defstruct unit: nil,
            monotonic: nil,
            # first order derivative, the difference of two monotonic values.
            offset: nil,
            # the first order derivative of offsets.
            skew: nil

  @typedoc "TimeValue struct"
  @type t() :: %__MODULE__{
          unit: System.time_unit(),
          monotonic: integer(),
          offset: integer(),
          skew: integer()
        }

  def new(unit, monotonic) when is_integer(monotonic) do
    %__MODULE__{
      unit: System.Extra.normalize_time_unit(unit),
      monotonic: monotonic
    }
  end

  def with_derivatives_from(
        %__MODULE__{} = v,
        %__MODULE__{} = previous
      )
      when is_nil(previous.offset) do
    # fallback: we only compute offset, no skew.

    new_offset = compute_offset(v, previous)

    %{v | offset: new_offset}
  end

  def with_derivatives_from(
        %__MODULE__{} = v,
        %__MODULE__{} = previous
      ) do
    new_offset = compute_offset(v, previous)

    new_skew = compute_skew(%{v | offset: new_offset}, previous)

    %{v | offset: new_offset, skew: new_skew}
  end

  defp compute_offset(
         %__MODULE__{monotonic: m1},
         %__MODULE__{monotonic: m2}
       )
       when m1 == m2,
       do: 0

  defp compute_offset(
         %__MODULE__{monotonic: monotonic, unit: unit},
         %__MODULE__{} = previous
       ) do
    if System.convert_time_unit(1, unit, previous.unit) < 1 do
      # invert conversion to avoid losing precision
      monotonic - System.convert_time_unit(previous.monotonic, previous.unit, unit)
    else
      System.convert_time_unit(monotonic, unit, previous.unit) - previous.monotonic
    end
  end

  defp compute_skew(
         %__MODULE__{monotonic: m1},
         %__MODULE__{monotonic: m2}
       )
       when m1 == m2,
       do: nil

  defp compute_skew(
         %__MODULE__{offset: o1},
         %__MODULE__{offset: o2}
       )
       when o1 == o2,
       do: 0

  defp compute_skew(
         %__MODULE__{offset: offset} = v,
         %__MODULE__{} = previous
       )
       when not is_nil(offset) do
    #    offset_delta =
    if System.convert_time_unit(1, v.unit, previous.unit) < 1 do
      # invert conversion to avoid losing precision
      offset - System.convert_time_unit(previous.offset, previous.unit, v.unit)
    else
      System.convert_time_unit(offset, v.unit, previous.unit) - previous.offset
    end

    # proportional should be done somewhere else (might be relative to a different clock...)
    #      IO.inspect(offset_delta)
    #
    #      IO.inspect((v.monotonic - previous.monotonic))
    #    # TODO : FIX THIS : what about two equal monotonic time
    #    # TODO : why isnt it the offset already calculated ??
    #    # Note : skew is allowed to be a float, to keep some precision in time computation,
    #    # despite division by a potentially large radical.
    #    offset_delta / (v.monotonic - previous.monotonic)
  end
end

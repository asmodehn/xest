defmodule XestClock.TimeValue do
  alias XestClock.Time

  def with_derivatives_from(
        %Time.Value{} = v,
        %Time.Value{} = previous
      )
      when is_nil(previous.offset) do
    # fallback: we only compute offset, no skew.

    new_offset = compute_offset(v, previous)

    %{v | offset: new_offset}
  end

  def with_derivatives_from(
        %Time.Value{} = v,
        %Time.Value{} = previous
      ) do
    new_offset = compute_offset(v, previous)

    new_skew = compute_skew(%{v | offset: new_offset}, previous)

    %{v | offset: new_offset, skew: new_skew}
  end

  defp compute_offset(
         %Time.Value{value: m1},
         %Time.Value{value: m2}
       )
       when m1 == m2,
       do: 0

  defp compute_offset(
         %Time.Value{value: monotonic, unit: unit},
         %Time.Value{} = previous
       ) do
    if System.convert_time_unit(1, unit, previous.unit) < 1 do
      # invert conversion to avoid losing precision
      monotonic - System.convert_time_unit(previous.value, previous.unit, unit)
    else
      System.convert_time_unit(monotonic, unit, previous.unit) - previous.value
    end
  end

  defp compute_skew(
         %Time.Value{value: m1},
         %Time.Value{value: m2}
       )
       when m1 == m2,
       do: nil

  defp compute_skew(
         %Time.Value{offset: o1},
         %Time.Value{offset: o2}
       )
       when o1 == o2,
       do: 0

  defp compute_skew(
         %Time.Value{offset: offset} = v,
         %Time.Value{} = previous
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

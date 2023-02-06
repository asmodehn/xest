defmodule XestClock.Stream.Timed.Proxy do
  #   hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System
  # hiding Elixir.System to make sure we do not inadvertently use it
  #  alias XestClock.Process

  #  alias XestClock.Stream.Timed
  alias XestClock.Time

  #  def with_offset(enum) do
  #    Stream.transform(enum, nil fn
  #      {i, %Timed.LocalStamp{} = lts}, last_offset ->
  #        # we save lst as acc to be checked by next element
  #        {[{i, lts}], 0}
  #
  #      {i, %Timed.LocalStamp{} = new_lts}, %Timed.LocalStamp{} = last_lts ->
  #    end)
  #  end

  #  def proxy(enum) do
  #    Stream.transform(enum, nil, fn
  #    # last elem as accumulator (to be used for next elem computation)
  #      si, nil -> IO.inspect("initialize")
  #                   {[si], si}
  #      # given a remote timevalue and a local timestamp in accumulator... TODO
  #      # two cases : TODO
  #      si, {%TimeValue{} = remote_tv, %TimeValue{} = local_ts} ->
  #        IO.inspect("generate with #{si |> elem(0)}")
  #
  #        local_now = TimeValue.new(local_ts.unit, System.monotonic_time(local_ts.unit))
  #                                 |> TimeValue.with_derivatives_from(local_ts)
  #                    |> IO.inspect()
  #
  #        generated = TimeValue.new(remote_tv.unit, remote_tv.monotonic + local_now.offset)
  #                                 |> TimeValue.with_derivatives_from(remote_tv)
  #                      |> IO.inspect()
  #
  #        #CAREFUL: this merges two different values to estimate error
  #        delta_skew = local_now.skew
  #
  #        # if we are still within acceptable error range
  #        if local_now.offset < limit do
  #
  #           {[{generated, local_now}, si], {remote_tv, local_ts}}
  #        else
  #          # grabbing new value from stream
  #           {[si], {remote_tv, local_ts}}
  #
  #        end
  #         #TODO : clauses with local timestamp instead of value...
  #    end)

  #  def proxy(enum) do
  #    Stream.transform(enum, nil, fn
  #      # last elem as accumulator (to be used for next elem computation)
  #      si, nil ->
  #        IO.inspect("initialize")
  #        {[si], si}
  #
  #      si,
  #      {%Time.Value{offset: remote_offset},
  #       %Timed.LocalStamp{monotonic: %Time.Value{offset: local_offset}}}
  #      when is_nil(remote_offset) or is_nil(local_offset) ->
  #        # we dont have the offset in at least one of the args
  #        {[si], si}
  #
  #      # -> not enough to estimate, we need both offset (at least two ticks of each timevalues)
  #
  #      si,
  #      {%Time.Value{} = remote_tv,
  #       %Timed.LocalStamp{monotonic: %Time.Value{offset: local_offset}} = local_ts} ->
  #        local_now =
  #          Timed.LocalStamp.now(local_ts.unit) |> Timed.LocalStamp.with_previous(local_ts)
  #
  #        {est, err} = compute_estimate(remote_tv, local_ts.monotonic, local_now.monotonic)
  #
  #        # TODO : maybe a PId controller would be better ? (error could improve overtime maybe ? )
  #
  #        # TODO : define some accuracy target... local_offset -> accepted error depends on the local_offset ???
  #        # error too large, retrieve the next remote tick...
  #        if err < local_offset do
  #          # keep same accumulator to compute next time
  #          # and return estimation
  #          {[
  #             {est, local_now},
  #             si
  #           ], {remote_tv, local_ts}}
  #        else
  #          {[si], si}
  #        end
  #    end)
  #  end

  @doc """
    Estimates the current remote now, simply adding the local_offset to the last known remote time

     If we denote by [-1] the previous measurement:
      remote_now = remote_now[-1] + (local_now - localnow[-1])
     where (local_now - localnow[-1]) = local_offset (kept inthe timeVaue structure)

  This comes from the intuitive newtonian assumption that time flows "at similar speed" in the remote location.
    Note this is only true if the remote is not moving too fast relatively to the local machine.

    Here we also need to estimate the error in case this is not true, or both clocks are not in sync for any reason.

  Let's expose a potential slight linear skew to the remote clock (relative to the local one) and calculate the error

  remote_now = (remote_now - remote_now[-1]) + remote_now[-1]
             = (remote_now - remote_now[-1]) / (local_now - local_now[-1]) * (local_now -local_now[-1]) + remote_now[-1]

  we can see (local_now - local_now[-1]) is the time elapsed and the factor (remote_now - remote_now[-1]) / (local_now - local_now[-1])
    is the skew between the two clocks, since we do not assume them to be equal any longer.
    This can be rewritten with local_offset = local_now - local_now[-1]:

    remote_now = remote_offset / local_offset * local_offset + remote_now[-1]

    remote_offset is unknown, but can be estimated in this setting, if we suppose the skew is the same as it was in the previous step,
    since we have the previous offset difference of both remote and local in the time value struct
      let remote_skew = remote_offset[-1] / local_offset[-1]
          remote_now = remote_skew * local_offset + remote_now[-1]

    Given our previous estimation, we can calculate the error, by removing the estimation from the previous formula:

      err = remote_skew * local_offset + remote_now[-1] - remote_now[-1] - local_offset
          = (remote_skew - 1) * local_offset

  """
  def compute_estimate(
        %Time.Value{} = last_remote,
        %Time.Value{} = last_local,
        %Time.Value{} = local_now
      ) do
    # estimate current remote now with current local now
    est = estimate_now(last_remote, local_now)
    # compute previous skew
    previous_skew = skew(last_remote, last_local)
    # since we assume previous skew will also be current skew (relative to time passed locally)
    err = local_now.offset * (previous_skew - 1)

    # Note this is the current offset -> longer we wait to get a new measurement, the more we risk errors...
    {est, err}
  end

  # TODO : these should probably move to timevalue...

  def estimate_now(%Time.Value{} = last_remote, %Time.Value{} = local_now) do
    # Here we always convert local time, since we want to keep remote precision in the estimate
    converted_offset =
      System.convert_time_unit(local_now.offset, local_now.unit, last_remote.unit)

    %Time.Value{
      unit: last_remote.unit,
      value: last_remote.value + converted_offset,
      offset: converted_offset
    }
  end

  @doc """
  Given how estimate_now is computed (see doc) the skew is calculated as the remote offset relatively
  to the local offset
  """
  @spec skew(Time.Value.t(), Time.Value.t()) :: float
  def skew(%Time.Value{} = remote, %Time.Value{} = local) do
    if System.convert_time_unit(1, remote.unit, local.unit) < 1 do
      # invert conversion to avoid losing precision
      remote.offset / System.convert_time_unit(local.offset, local.unit, remote.unit)
    else
      System.convert_time_unit(remote.offset, remote.unit, local.unit) / local.offset
    end
    |> IO.inspect()
  end
end

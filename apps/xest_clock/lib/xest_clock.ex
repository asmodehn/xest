defmodule XestClock do
  # TODO: __using__ so that a connector can use XestClock,
  # and only indicate how to retrieve the current time (web request or so),
  # To get a gen_server ticking as a proxy of the remote clock.
  # The stream machinery should be hidden from the user for simple usage.

  @moduledoc """

  XestClock manages local and remote clocks as either stateless streams or stateful processes,
  dealing with monotonic time.

  The stateful processes are simple gen_servers manipulating the streams,
  but they have the most intuitive usage.

  The streams of timestamps are the simplest to exhaustively test,
  and can be used no matter what your process architecture is for your application.

  This package is useful when you need to work with remote clocks, which cannot be queried very often,
  yet you still need some robust tracking of elapsed time on a remote system,
  by leveraging your local system clock, and assuming remote clocks are deviating only slowly from your local system clock...

  Sensible defaults have been set in child_specs for the Clock Server, and you should always use it with a Supervisor,
  so that you can rely on it being always present, even when there is bad network weather conditions.
  Calling XestClock.Server.start_link yourself, you will have to explicitly pass the Stream you want the Server to work with.
  """

  #  alias XestClock.StreamClock
  #
  #  @doc """
  #    A StreamClock for a remote clock.
  #
  #    Note this internally proxy the clock, so that remote requests are actually done
  #    only when necessary to minimise estimation error
  #
  #    Therefore this is a stream based on localclock, with offset adjustment
  #    based on remote measurements
  #  """
  #  def new(unit, origin \\ System) do
  #    clock = XestClock.new(origin, unit,
  #      Stream.repeatedly(
  #        # getting local time  monotonically
  #        fn -> System.monotonic_time(nu) end
  #      ))
  #
  #    if origin != System do
  #      # estimate remote from previous requests
  #      clock |> Stream.transform(nil, fn
  #        # last elem as accumulator (to be used for next elem computation)
  #      ls, nil ->
  #        IO.inspect("initialize")
  #        remote_tv = origin.ticks(1)
  #        {[remote_tv], remote_tv}
  #
  #      %Timed.LocalStamp{monotonic: %TimeValue{offset: local_offset}}, last_remote ->
  #      when is_nil(local_offset) or is_nil(last_remote.offset) ->
  #        # we dont have the offset, still initializing
  #        remote_tv = origin.ticks(1)
  #        {[remote_tv], si}
  #
  #
  #      # -> not enough to estimate, we need both offset (at least two ticks of each timevalues)
  #
  #      si, %Timed.LocalStamp{monotonic: %TimeValue{offset: local_offset}} = local_ts ->
  #        local_now =
  #          Timed.LocalStamp.now(local_ts.unit) |> Timed.LocalStamp.with_previous(local_ts)
  #
  #        # compute previous skew
  #        previous_skew = skew(last_remote, last_local)
  #        # since we assume previous skew will also be current skew (relative to time passed locally)
  #        err = local_now.offset * (previous_skew - 1)
  #        #TODO : maybe pid controller would be better...
  #        if err > local_offset do
  #            remote_tv = origin.ticks(1)
  #        else
  #
  #          # estimate current remote now with current local now
  #          est = estimate_now(last_remote, local_now.monotonic)
  #          {[est], si}  # TODO : put error in estimation timevalue
  #        end
  #
  #
  #
  #                        end)
  #
  #    end
  #
  #
  #
  #  end
end

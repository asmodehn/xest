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

  alias XestClock.StreamClock

  @doc """
    A StreamClock for a remote clock.

    Note this internally proxy the clock, so that remote requests are actually done
    only when necessary to minimise estimation error

    Therefore this is a stream based on localclock, with offset adjustment
    based on remote measurements
  """
  def new(unit, System), do: StreamClock.new(XestClock.System, unit)

  #
  #      def new(unit, origin) when is_atom(origin) do
  #      {:ok, pid} = origin.start_link(unit)
  #        new(unit, pid)
  #      end
  #
  #      def new(unit, origin) when is_pid(origin) do
  #
  #        remote = StreamClock.new(origin, unit, Stream.repeatedly(fn
  #                            -> origin.tick(pid)
  #        end))
  #
  #        # TODO :split this into useful stream operators...
  #        # estimate remote from previous requests
  #        clock |> Stream.transform(nil, fn
  #          # last elem as accumulator (to be used for next elem computation)
  #        %Timed.LocalStamp{} = local_now, nil ->
  #          IO.inspect("initialize")
  #          # Note : we need 2 ticks from the server to start estimating remote time
  #          [_, t2] = origin.ticks(2)
  #
  #          {
  #            %Timestamp{ts: %TimeValue{} = last_remote},
  #            %Timed.LocalStamp{monotonic: %TimeValue{} = last_local}
  #          } = t2
  #
  #          # estimate current remote now with current local now
  #          est = Timed.Proxy.estimate_now(last_remote, local_now.monotonic)
  #          {[est], t2}
  #
  #        # -> not enough to estimate, we need both offset (at least two ticks of each timevalues)
  #
  #        %Timed.LocalStamp{} = local_now,
  #        {%Timestamp{ts: %TimeValue{} = last_remote},
  #          %Timed.LocalStamp{monotonic: %TimeValue{} = last_local}} = last_remote_tick ->
  #
  #          # compute previous skew
  #          previous_skew = Timed.Proxy.skew(last_remote, last_local)
  #          # since we assume previous skew will also be current skew (relative to time passed locally)
  #          delta_since_request = (local_now.monotonic - last_local.monotonic)
  #          err = delta_since_request * (previous_skew - 1)
  #
  #          #TODO : maybe pid controller would be better...
  #          # TODO : accuracy limit, better option ?
  #          if err > delta_since_request do
  #              remote_tv = origin.ticks(1)
  #              {[remote_tv], remote_tv}
  #          else
  #            # estimate current remote now with current local now
  #            est = Timed.Proxy.estimate_now(last_remote, local_now.monotonic)
  #            {[est], last_remote_tick}  # TODO : put error in estimation timevalue
  #          end
  #
  #        end)
  #          # TODO :enforce monotonicity after estimation
  #          # TODO: handle unit conversion.
  #
  #      end
end

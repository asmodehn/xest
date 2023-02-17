defmodule XestClock.Server do
  @moduledoc """
  This is a GenServer holding a stream (designed from GenStage.Streamer as in Elixir 1.14)
    and setup so that a client process can ask for one element at a time, synchronously.
  We attempt to keep the same semantics, so the synchronous request will immediately trigger an event to be sent to all subscribers.
  """

  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System
  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.Process

  alias XestClock.Stream.Timed
  #  alias XestClock.Stream.Limiter
  #  alias XestClock.Time

  # TODO : better type for continuation ?
  @type internal_state :: {Stream.t(), continuation :: any()}

  #  # the actual callback needed by the server
  #    @callback init({atom(), System.time_unit()}) ::
  #              {:ok, state}
  #              | {:ok, state, timeout | :hibernate | {:continue, continue_arg :: term}}
  #              | :ignore
  #              | {:stop, reason :: any}
  #            when state: any
  @callback handle_remote_unix_time() :: Time.Value.t()
  @callback handle_offset({Enumerable.t(), any(), internal_state}) ::
              {Time.Value.t(), internal_state}

  # callbacks to nudge the user towards code clarity with an explicit interface
  # good or bad idae ???
  @callback ticks(pid(), integer()) :: [XestClock.Time.Value.t()]

  #  @optional_callbacks init: 1
  # TODO : see GenServer to add appropriate behaviours one may want to (re)define...

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      ## TODO : alias System and Time ? goal is to prevent access to elixir's one,
      #      but use XestClock ones by default for better testing...
      @behaviour XestClock.Server

      # Let GenServer do the usual GenServer stuff...
      # After all the start and init work the same...
      use GenServer

      # GenServer child_spec is good enough for now.

      # we define the init matching the callback
      @doc false
      @impl GenServer
      def init(_init_arg) do
        #  default init behaviour (overridable)
        XestClock.Server.init(
          XestClock.Stream.repeatedly_throttled(
            # default period limit of a second
            1000,
            # getting remote time via callback (should have been setup by __using__ macro)
            &handle_remote_unix_time/0
          )
        )
      end

      defoverridable init: 1

      # TODO : :ticks to more specific atom (library style)...
      # IDEA : stamp for passive, ticks for proactive ticking
      # possibly out of band/without client code knowing -> events / pubsub
      @doc false
      @impl GenServer
      def handle_call({:ticks, demand}, _from, {stream, continuation, last_result}) do
        # cache on the client side (it is impure, so better keep it on the outside)
        # REALLY ???

        #        max_call_rate(fn ->
        # Ref: https://hexdocs.pm/gen_stage/GenStage.html#c:handle_call/3
        # we immediately return the result of the computation,
        # TODO: but we also set it to be dispatch as an event (other subscribers ?),
        # just as a demand of 1 would have.
        {result, new_continuation} = XestClock.Stream.Ticker.next(demand, continuation)

        {:reply, result, {stream, new_continuation, List.last(result)}}
      end

      @doc false
      @impl GenServer
      def handle_call({:offset}, _from, {stream, continuation, last_result}) do
        {result, new_state} = handle_offset({stream, continuation, last_result})

        {:reply, result, new_state}
      end

      #  a simple default implementation, straight forward...
      @doc false
      @impl XestClock.Server
      def handle_offset(state) do
        XestClock.Server.compute_offset(state)
      end

      # this is the default signaling to the user it has not been defined
      @doc false
      @impl XestClock.Server
      def handle_remote_unix_time() do
        proc =
          case Process.info(self(), :registered_name) do
            {_, []} -> self()
            {_, name} -> name
          end

        # We do this to trick Dialyzer to not complain about non-local returns.
        case :erlang.phash2(1, 1) do
          0 ->
            raise "attempted to call XestClock.Template #{inspect(proc)} but no handle_remote_unix_time/3 clause was provided"

          1 ->
            # state here could be the current (last in stream) time ?
            {:stop, {:bad_call}, nil}
        end
      end

      defoverridable handle_offset: 1
      defoverridable handle_remote_unix_time: 0
    end
  end

  # TODO : better interface for min_handle_remote_period...
  def init(timevalue_stream) do
    streamclock =
      timevalue_stream
      # TODO :: use this as indicator of what to do in streamclock... or not ???
      |> XestClock.Stream.monotone_increasing()

      # we compute local delta here in place where we have easy access to element in the stream
      |> Timed.LocalDelta.compute()

    # TODO : maybe we can make the first tick here, so the second one needed for estimation
    # will be done on first request ? seems better than two at first request time...
    # TODO : if requests are implicit in here we can just schedule the first one...

    # GOAL : At this stage the stream at one element has all information
    # related to previous elements for a client to be able
    # to build his own estimation of the remote clock

    {:ok, {streamclock, XestClock.Stream.Ticker.new(streamclock), nil}}
  end

  def compute_offset({stream, continuation, last_result}) do
    case last_result do
      nil ->
        # force tick
        {result, new_continuation} = XestClock.Stream.Ticker.next(1, continuation)
        {rts, lts, dv} = List.last(result)

        {
          # CAREFUL erasing error: nil here
          %{Timed.LocalDelta.offset(dv, lts) | error: 0},
          # new state
          {stream, new_continuation, {rts, lts, dv}}
        }

      # TODO : this in a special stream ??

      # first offset can have an error of 0, to get things going...
      # TODO : cleaner way to handle these cases ??? with an ok tuple ?
      {rts, lts, dv} ->
        offset = Timed.LocalDelta.offset(dv, lts)

        # Note the maximum precision we aim for is millisecond
        # network is usually not faster, and any slower would only hide offset estimation via skew.
        #               offset.error > System.convert_time_unit(1, :millisecond, offset.unit) do
        # Another option is to aim for the clock precision, as more precise doesnt have any meaning
        if is_nil(offset.error) or
             offset.error > System.convert_time_unit(1, rts.unit, offset.unit) do
          # force tick
          # TODO : can we do something here so that the next request can come a bit later ???
          #
          {result, new_continuation} = XestClock.Stream.Ticker.next(1, continuation)
          {rts, lts, dv} = List.last(result)

          {
            Timed.LocalDelta.offset(dv, lts),
            # new_state
            {stream, new_continuation, {rts, lts, dv}}
          }
        else
          {
            offset,
            # new_state
            {stream, continuation, {rts, lts, dv}}
          }
        end
    end
  end

  # we define a default start_link matching the default child_spec of genserver
  def start_link(module, opts \\ []) do
    # TODO: use this to pass options to the server

    GenServer.start_link(
      module,
      opts
    )
  end

  @spec ticks(pid(), integer()) :: [
          {XestClock.Timestamp.t(), XestClock.Stream.Timed.LocalStamp.t(),
           XestClock.Stream.Timed.LocalDelta.t()}
        ]
  def ticks(pid \\ __MODULE__, demand) do
    GenServer.call(pid, {:ticks, demand})
  end

  #  @spec previous_tick(pid()) ::
  #          {XestClock.Timestamp.t(), XestClock.Stream.Timed.LocalStamp.t(),
  #           XestClock.Stream.Timed.LocalDelta.t()}
  #  def previous_tick(pid \\ __MODULE__) do
  #    {_stream, _continuation, last} = :sys.get_state(pid)
  #    last
  #  end

  def offset(pid \\ __MODULE__) do
    GenServer.call(pid, {:offset})
  end

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

  @spec monotonic_time_value(pid, System.time_unit()) :: Time.Value.t()
  def monotonic_time_value(pid \\ __MODULE__, unit) do
    # Check if retrieving time is actually needed
    offset = offset(pid) |> IO.inspect()

    XestClock.Time.Value.sum(
      Timed.LocalStamp.now(unit)
      |> Timed.LocalStamp.as_timevalue(),
      offset
    )
    |> XestClock.Time.Value.convert(unit)
  end

  @spec monotonic_time(pid, System.time_unit()) :: integer
  def monotonic_time(pid \\ __MODULE__, unit) do
    monotonic_time_value(pid, unit)
    |> Map.get(:value)

    # TODO : what to do with skew / error ???
  end
end

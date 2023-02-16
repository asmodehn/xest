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
  @callback handle_remote_unix_time(System.time_unit()) :: Time.Value.t()

  # callbacks to nudge the user towards code clarity with an explicit interface
  # good or bad idae ???
  @callback start_link(atom, System.time_unit()) :: GenServer.on_start()
  @callback ticks(pid(), integer()) :: [XestClock.Time.Value.t()]

  #  @optional_callbacks init: 1
  # TODO : see GenServer to add appropriate behaviours one may want to (re)define...

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour XestClock.Server

      # Let GenServer do the usual GenServer stuff...
      # After all the start and init work the same...
      use GenServer

      # GenServer child_spec is good enough for now.

      # we define the init matching the callback
      @doc false
      @impl true
      def init({origin, unit}) do
        #  default init behaviour (overridable)
        XestClock.Server.init({origin, unit}, &handle_remote_unix_time/1)

        # TODO : maybe allow client to pass his local clock that will be used for estimation later on ?
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

      # we add just one callback. this is the default signaling to the user it has not been defined
      @doc false
      @impl XestClock.Server
      def handle_remote_unix_time(unit) do
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
            {:stop, {:bad_call, unit}, nil}
        end
      end

      defoverridable handle_remote_unix_time: 1
    end
  end

  # TODO : better interface for min_handle_remote_period...
  def init({_origin, unit}, remote_unit_time_handler, min_handle_remote_period \\ 1000) do
    # time_unit also function as a rate (parts per second)
    #    min_period = if is_nil(min_handle_remote_period), do: round(unit), else: min_handle_remote_period

    # here we leverage streamclock, although we keep a usual server interface...
    #      XestClock.StreamClock.new(
    #        origin,
    #        unit,
    # throttling remote requests, adding local timestamp
    streamclock =
      XestClock.Stream.repeatedly_throttled(
        min_handle_remote_period,
        # getting remote time via callback (should have been setup by __using__ macro)
        fn -> remote_unit_time_handler.(unit) end
      )
      #        |> Stream.map(fn   # adding local timestamp error to time value error
      #          {tv, lts} ->
      #        end)
      # TODO :: use this as indicator of what to do in streamclock... or not ???
      |> XestClock.Stream.monotone_increasing()

      # we compute local delta here in place where we have easy access to element in the stream
      |> Timed.LocalDelta.compute()

    # GOAL : At this stage the stream at one element has all information
    # related to previous elements for a client to be able
    # to build his own estimation of the remote clock

    {:ok, {streamclock, XestClock.Stream.Ticker.new(streamclock), nil}}
  end

  # we define a default start_link matching the default child_spec of genserver
  def start_link(module, unit, opts \\ []) do
    GenServer.start_link(module, {module, unit}, opts)
  end

  @spec ticks(pid(), integer()) :: [
          {XestClock.Timestamp.t(), XestClock.Stream.Timed.LocalStamp.t(),
           XestClock.Stream.Timed.LocalDelta.t()}
        ]
  def ticks(pid \\ __MODULE__, demand) do
    GenServer.call(pid, {:ticks, demand})
  end

  @spec previous_tick(pid()) ::
          {XestClock.Timestamp.t(), XestClock.Stream.Timed.LocalStamp.t(),
           XestClock.Stream.Timed.LocalDelta.t()}
  def previous_tick(pid \\ __MODULE__) do
    {_stream, _continuation, last} = :sys.get_state(pid)
    last
  end

  #  @doc """
  #    compute the current error of the server from its state.
  #  Note we dont pass the time_unit here, lets return the best error estimate we can get.
  #    Conversion is better explicited on caller side if required.
  #  """
  #  @spec error(pid) :: {Time.Value.t(), Timed.LocalDelta.t()}
  #  def error(pid \\ __MODULE__) do
  #    case previous_tick(pid) do
  #      nil ->
  #        error = nil
  #
  #        delta = %Timed.LocalDelta{
  #          offset: nil,
  #          skew: nil
  #        }
  #
  #        {error, delta}
  #
  #      {_rts, lts, dv} ->
  #        error = Timed.LocalDelta.error_since(dv, lts)
  #
  #        {error, dv}
  #    end
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

  @spec monotonic_time_value(pid, System.time_unit(), System.time_unit()) :: Time.Value.t()
  def monotonic_time_value(pid \\ __MODULE__, unit, precision \\ :second) do
    # Check if retrieving time is actually needed
    offset =
      case previous_tick(pid) do
        nil ->
          # force tick
          {_rts, lts, dv} = List.first(ticks(pid, 1))
          %{Timed.LocalDelta.offset(dv, lts) | error: 0}

        # first offset can have an error of 0, to get things going...
        # TODO : cleaner way to handle these cases ??? with an ok tuple ?
        {_rts, lts, dv} ->
          offset = Timed.LocalDelta.offset(dv, lts)

          if is_nil(offset.error) or
               offset.error > System.convert_time_unit(1, precision, offset.unit) do
            # force tick
            # TODO : can we do something here so that the next request can come a bit later ???
            #
            {_rts, lts, dv} = List.first(ticks(pid, 1))
            Timed.LocalDelta.offset(dv, lts)
          else
            offset
          end
      end
      |> IO.inspect()

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

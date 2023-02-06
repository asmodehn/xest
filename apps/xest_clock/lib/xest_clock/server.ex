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
  @type internal_state :: {XestClock.StreamClock.t(), continuation :: any()}

  #  # the actual callback needed by the server
  #    @callback init({atom(), System.time_unit()}) ::
  #              {:ok, state}
  #              | {:ok, state, timeout | :hibernate | {:continue, continue_arg :: term}}
  #              | :ignore
  #              | {:stop, reason :: any}
  #            when state: any
  @callback handle_remote_unix_time(System.time_unit()) :: integer()

  # callbacks to nudge the user towards code clarity with an explicit interface
  # good or bad idae ???
  @callback start_link(atom, System.time_unit()) :: GenServer.on_start()
  @callback ticks(pid(), integer()) :: [XestClock.Timestamp.t()]

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
      def handle_call({:ticks, demand}, _from, {stream, continuation}) do
        # cache on the client side (it is impure, so better keep it on the outside)
        # REALLY ???

        #        max_call_rate(fn ->
        # Ref: https://hexdocs.pm/gen_stage/GenStage.html#c:handle_call/3
        # we immediately return the result of the computation,
        # TODO: but we also set it to be dispatch as an event (other subscribers ?),
        # just as a demand of 1 would have.
        {result, new_continuation} = XestClock.Stream.Ticker.next(demand, continuation)

        #            reply = {result, now}  # we have the timestamp, lets return it !
        #            {:reply, reply, {now, stream, new_continuation}}
        {:reply, result, {stream, new_continuation}}
        #          end, rate)
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
  def init({origin, unit}, remote_unit_time_handler, min_handle_remote_period \\ 1000) do
    # time_unit also function as a rate (parts per second)
    #    min_period = if is_nil(min_handle_remote_period), do: round(unit), else: min_handle_remote_period

    # here we leverage streamclock, although we keep a usual server interface...
    streamclock =
      XestClock.StreamClock.new(
        origin,
        unit,
        XestClock.Stream.repeatedly_throttled(
          min_handle_remote_period,
          # getting remote time via callback (should have been setup by __using__ macro)
          fn -> remote_unit_time_handler.(unit) end
        )
      )
      # Note these apply to the whole streamclock to stamp each event...
      # specifying unit so we do not rely on the System native unit.
      #      |> Timed.timed(unit)
      # requests should not be faster than rate_limit
      # Note: this will sleep if necessary, in server process, when the stream will be traversed.
      #      |> Limiter.max_rate(rate_limit)
      # we compute local delta here in place where we have easy access to element in the stream
      |> Timed.LocalDelta.compute()

    # GOAL : At this stage the stream at one element has all information
    # related to previous elements for a client to be able
    # to build his own estimation of the remote clock

    {:ok, {streamclock, XestClock.Stream.Ticker.new(streamclock)}}
  end

  # we define a default start_link matching the default child_spec of genserver
  def start_link(module, unit, opts \\ []) do
    GenServer.start_link(module, {module, unit}, opts)
  end

  @spec ticks(pid(), integer()) :: [{XestClock.Timestamp.t(), XestClock.LocalStamp.t()}]
  def ticks(pid \\ __MODULE__, demand) do
    GenServer.call(pid, {:ticks, demand})
  end
end

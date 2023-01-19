defmodule XestClock.Server do
  @moduledoc """
  This is a GenServer holding a stream (designed from GenStage.Streamer as in Elixir 1.14)
    and setup so that a client process can ask for one element at a time, synchronously.
  We attempt to keep the same semantics, so the synchronous request will immediately trigger an event to be sent to all subscribers.
  """

  # TODO : better type for continuation ?
  @type internal_state :: {XestClock.StreamClock.t(), continuation :: any()}

  # the actual callback needed by the server
  @callback handle_remote_unix_time(System.time_unit()) :: integer()

  # callbacks to nudge the user towards code clarity with an explicit interface
  @callback start_link(atom, System.time_unit()) :: GenServer.on_start()
  @callback ticks(pid(), integer()) :: [XestClock.Timestamp.t()]

  @optional_callbacks [
    # TODO : see GenServer to add appropriate behaviours one may want to (re)define...
  ]

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
      @impl GenServer
      def init({origin, unit}) do
        # here we leverage streamclock, although we keep a usual server interface...
        streamclock =
          XestClock.StreamClock.new(
            origin,
            unit,
            Stream.repeatedly(
              # getting remote time via callback
              fn -> handle_remote_unix_time(unit) end
            )
          )

        {:ok, {streamclock, XestClock.Stream.Ticker.new(streamclock)}}
      end

      # TODO : :ticks to more specific atom (library style)...
      # IDEA : stamp for passive, ticks for proactive ticking
      # possibly out of band/without client code knowing -> events / pubsub
      @doc false
      @impl GenServer
      def handle_call({:ticks, demand}, _from, {stream, continuation}) do
        # Ref: https://hexdocs.pm/gen_stage/GenStage.html#c:handle_call/3
        # we immediately return the result of the computation,
        # TODO: but we also set it to be dispatch as an event (other subscribers ?),
        # just as a demand of 1 would have.
        {reply, new_continuation} = XestClock.Stream.Ticker.next(demand, continuation)
        {:reply, reply, {stream, new_continuation}}
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

  # we define a default start_link matching the default child_spec of genserver
  def start_link(module, unit, opts \\ []) do
    GenServer.start_link(module, {module, unit}, opts)
  end

  @spec ticks(pid(), integer()) :: [XestClock.Timestamp.t()]
  def ticks(pid \\ __MODULE__, demand) do
    GenServer.call(pid, {:ticks, demand})
  end
end

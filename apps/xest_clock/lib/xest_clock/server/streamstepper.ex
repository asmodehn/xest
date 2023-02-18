defmodule XestClock.Server.StreamStepper do
  @moduledoc """
    A module implementing a simple streamstepper, to hide it from other server implementation,
    yet be able to mock its behaviour in tests.

  Note: The module is designed, so it is possible to combine it with other servers
         and it only defines ONE genserver.
  """

  @enforce_keys [:stream, :continuation]
  defstruct stream: nil,
            continuation: nil,
            backstep: []

  @typedoc "StreamStepper internal state"
  @type t() :: %__MODULE__{
          stream: Enumerable.t(),
          # TODO : better type for continuation ?
          continuation: fun(),
          backstep: List.t()
        }

  # behaviour of the stream stepper.
  @callback handle_ticks(integer, t()) :: {[result :: any()], t()}

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour XestClock.Server.StreamStepper

      use GenServer

      # GenServer child_spec is good enough for now.

      # we define the init matching the callback
      @doc false
      @impl GenServer
      def init(stream) do
        #  default init behaviour (overridable)
        XestClock.Server.StreamStepper.init(stream)
      end

      defoverridable init: 1

      # TODO : :ticks to more specific atom (library style)...
      # IDEA : stamp for passive, ticks for proactive ticking
      # possibly out of band/without client code knowing -> events / pubsub
      @doc false
      @impl GenServer
      def handle_call({:ticks, demand}, _from, %XestClock.Server.StreamStepper{} = state) do
        # Ref: https://hexdocs.pm/gen_stage/GenStage.html#c:handle_call/3
        # we immediately return the result of the computation,
        # TODO: but we also set it to be dispatch as an event (other subscribers ?),
        # just as a demand of 1 would have.

        {:reply, result, new_state} = handle_ticks(demand, state)
        {:reply, result, new_state}
      end

      @doc false
      @impl XestClock.Server.StreamStepper
      # default behaviour implementation, delegated to the streamstepper module
      def handle_ticks(demand, %XestClock.Server.StreamStepper{} = state) do
        XestClock.Server.StreamStepper.handle_ticks(demand, state)
      end

      defoverridable handle_ticks: 2
    end
  end

  # Because stream stepper is also usable directly
  use GenServer

  # we define a default start_link matching the default child_spec of genserver
  # This one allows to pass a module, so that a module __using__ streamstepper can pass his own name
  def start_link(module, stream, opts \\ []) when is_atom(module) and is_list(opts) do
    # TODO: use this to pass options to the server via init_arg

    GenServer.start_link(module, stream, opts)
  end

  # we redefine childspec here so that starting the streamstepper by itself works with start_link/3...
  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [__MODULE__, init_arg]}
    }
  end

  @spec ticks(pid(), integer()) :: [result :: any()]
  def ticks(pid \\ __MODULE__, demand) do
    GenServer.call(pid, {:ticks, demand})
  end

  @impl GenServer
  # TODO: options : init_call: true/false, proactive: true/false
  def init(stream) do
    # TODO : maybe we can make the first tick here, so the second one needed for estimation
    # will be done on first request ? seems better than two at first request time...
    # TODO : if requests are implicit in here we can just schedule the first one...

    # GOAL : At this stage the stream at one element has all information
    # related to previous elements for a client to be able
    # to build his own estimation of the remote clock

    {:ok,
     %__MODULE__{
       stream: stream,
       continuation: XestClock.Stream.Ticker.new(stream),
       backstep: []
     }}
  end

  # Because stream stepper is also usable directly
  @doc false
  @impl GenServer
  def handle_call({:ticks, demand}, _from, %XestClock.Server.StreamStepper{} = state) do
    # Ref: https://hexdocs.pm/gen_stage/GenStage.html#c:handle_call/3
    # we immediately return the result of the computation,
    # TODO: but we also set it to be dispatch as an event (other subscribers ?),
    # just as a demand of 1 would have.
    {:reply, result, new_state} = handle_ticks(demand, state)
    {:reply, result, new_state}
  end

  @doc false
  def handle_ticks(demand, %XestClock.Server.StreamStepper{
        stream: s,
        continuation: c,
        backstep: b
      }) do
    {result, new_continuation} = XestClock.Stream.Ticker.next(demand, c)

    {:reply, result,
     %XestClock.Server.StreamStepper{
       stream: s,
       continuation: new_continuation,
       # TODO : variable number of backsteps
       backstep: (b ++ result) |> Enum.take(-1)
     }}
  end

  # TODO : maybe separate the client and server part ?
  # it seems this module is already semantically heavy (self / using usage...)
end

defmodule XestClock.ClockServer do
  #  @callback ticks(pid(), integer()) :: [XestClock.Timestamp.t()]
  #  def ticks(pid \\ __MODULE__, demand) do
  #    GenServer.call(pid, {:ticks, demand})
  #  end

  @callback handle_remote_unix_time(System.time_unit()) :: integer()

  @doc false
  defmacro __using__(opts) do
    IO.inspect(opts)

    quote location: :keep, bind_quoted: [opts: opts] do
      unless Module.has_attribute?(__MODULE__, :doc) do
        @doc """
        This is a GenServer holding a stream (designed from GenStage.Streamer as in Elixir 1.14)
          and setup so that a client process can ask for one element at a time, synchronously.
        """
      end

      def child_spec({origin, unit}) do
        default = %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [XestClock.StreamClock.new({origin, unit})]}
        }

        Supervisor.child_spec(default, unquote(Macro.escape(opts)))
      end

      defoverridable child_spec: 1

      # reusing Ticker implementation as it is thoroughly tested
      use GenServer

      require XestClock.Ticker

      @impl true
      def init({origin, unit}) do
        # creates an internal streamclock, calling handle_retrieve_time whenever necessary
        XestClock.StreamClock.new(
          origin,
          unit,
          Stream.repeatedly(fn -> handle_remote_unix_time(unit) end)
        )
        |> XestClock.Ticker.init()
      end

      @impl true
      def handle_call({:ticks, demand}, from, continuation) do
        XestClock.Ticker.handle_call({:ticks, demand}, from, continuation)
      end

      # Adding special code for clockserver, following usual GenServer design
      @behaviour XestClock.ClockServer

      @doc false
      @impl true
      def handle_remote_unix_time(unit) do
        proc =
          case Process.info(self(), :registered_name) do
            {_, []} -> self()
            {_, name} -> name
          end

        # We do this to trick Dialyzer to not complain about non-local returns.
        case :erlang.phash2(1, 1) do
          0 ->
            raise "attempted to call XestClock.Template #{inspect(proc)} but no handle_retrieve_time/3 clause was provided"

          1 ->
            # state here could be the current (last in stream) time ?
            {:stop, {:bad_call, unit}, nil}
        end
      end

      defoverridable handle_remote_unix_time: 1
    end
  end
end

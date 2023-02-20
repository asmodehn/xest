defmodule XestClock.Server do
  @moduledoc """
  This is a GenServer holding a stream (designed from GenStage.Streamer as in Elixir 1.14)
    and setup so that a client process can ask for one element at a time, synchronously.
  We attempt to keep the same semantics, so the synchronous request will immediately trigger an event to be sent to all subscribers.
  """

  # hiding Elixir.System to make sure we do not inadvertently use it
  alias XestClock.System

  alias XestClock.Stream.Timed
  #  alias XestClock.Stream.Limiter
  #  alias XestClock.Time

  alias XestClock.Server.StreamStepper

  @callback handle_offset({Enumerable.t(), any(), StreamStepper.t()}) ::
              {Time.Value.t(), StreamStepper.t()}

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
      use StreamStepper

      # GenServer child_spec is good enough for now.

      # Lets define a start_link by default:
      def start_link(stream, opts \\ []) when is_list(opts) do
        XestClock.Server.start_link(__MODULE__, stream, opts)
      end

      # we define the init matching the callback
      @doc false
      @impl GenServer
      def init(function_call) do
        #  default init behaviour (overridable)
        {:ok,
         XestClock.Server.init(
           XestClock.Stream.repeatedly_throttled(
             # default period limit of a second
             1000,
             # getting remote time via callback (should have been setup by __using__ macro)
             function_call
           )
         )}
      end

      defoverridable init: 1

      @doc false
      @impl GenServer
      def handle_call(
            {:offset},
            _from,
            %StreamStepper{stream: s, continuation: c, backstep: b} = state
          ) do
        {result, %StreamStepper{} = new_state} = handle_offset(state)

        {:reply, result, new_state}
      end

      #  a simple default implementation, straight forward...
      @doc false
      @impl XestClock.Server
      def handle_offset(%StreamStepper{} = state) do
        XestClock.Server.compute_offset(state)
      end

      defoverridable handle_offset: 1
    end
  end

  # TODO : better interface for min_handle_remote_period...
  def init(timevalue_stream) do
    stream =
      timevalue_stream
      # TODO :: use this as indicator of what to do in streamclock... or not ???
      |> XestClock.Stream.monotone_increasing()

      # we compute local delta here in place where we have easy access to element in the stream
      |> Timed.LocalDelta.compute()

    # GOAL : At this stage the stream at one element has all information
    # related to previous elements for a client to be able
    # to build his own estimation of the remote clock
    StreamStepper.init(stream)
  end

  def compute_offset(%StreamStepper{stream: s, continuation: c, backstep: b}) do
    case List.last(b) do
      nil ->
        # force tick
        {result, new_continuation} = XestClock.Stream.Ticker.next(1, c)
        {rts, lts, dv} = List.last(result)

        {
          # CAREFUL erasing error: nil here
          %{Timed.LocalDelta.offset(dv, lts) | error: 0},
          # new state  # TODO : adjust backstep... in streamstepper !!
          %StreamStepper{stream: s, continuation: new_continuation, backstep: [{rts, lts, dv}]}
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
          {result, new_continuation} = XestClock.Stream.Ticker.next(1, c)
          {rts, lts, dv} = List.last(result)

          {
            Timed.LocalDelta.offset(dv, lts),
            # new_state # TODO : adjust backstep... in stream stepper !!!
            %StreamStepper{stream: s, continuation: new_continuation, backstep: [{rts, lts, dv}]}
          }
        else
          {
            offset,
            # new_state  # TODO : adjust backstep... in stream stepper !!!
            %StreamStepper{stream: s, continuation: c, backstep: [{rts, lts, dv}]}
          }
        end
    end
  end

  # we define a default start_link matching the default child_spec of genserver
  def start_link(module, stream, opts \\ []) do
    # TODO: use this to pass options to the server

    StreamStepper.start_link(module, stream, opts)
  end

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

  def remote_time_value(pid \\ __MODULE__, unit) do
    # Check if retrieving time is actually needed
    offset = offset(pid) |> IO.inspect()

    XestClock.Time.Value.sum(
      Timed.LocalStamp.now(unit)
      |> Timed.LocalStamp.system_time(),
      offset
    )
    |> XestClock.Time.Value.convert(unit)
  end

  @spec monotonic_time_value(pid, System.time_unit()) :: Time.Value.t()
  def monotonic_time_value(pid \\ __MODULE__, unit) do
    # Check if retrieving time is actually needed
    offset = offset(pid) |> IO.inspect()

    XestClock.Time.Value.sum(
      XestClock.Time.Value.new(unit, Timed.LocalStamp.now(unit).monotonic),
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

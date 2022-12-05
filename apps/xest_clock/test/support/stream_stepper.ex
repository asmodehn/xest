defmodule XestClock.StreamStepper do
  # Designed from GenStage.Streamer
  @moduledoc """
  This is a GenStage, abused to hold a stream (designed from GenStage.Streamer as in Elixir 1.14)
    and setup so that a client process can ask for one element at a time, synchrounously.
  We attempt to keep the same semantics, so the synchronous request will immediately trigger an event to be sent to all subscribers.

  Currently it is just a support for testing, but it begs to wonder if we need something like this, maybe more "lightweight"
    into xestclock code, to manage the proxy data, while stream executes...
  """

  use GenStage

  def start_link({stream, opts}) do
    {:current_stacktrace, [_info_call | stack]} = Process.info(self(), :current_stacktrace)
    GenStage.start_link(__MODULE__, {stream, stack, opts}, opts)
  end

  def init({stream, stack, opts}) do
    continuation =
      &Enumerable.reduce(stream, &1, fn
        x, {acc, 1} -> {:suspend, {[x | acc], 0}}
        x, {acc, counter} -> {:cont, {[x | acc], counter - 1}}
      end)

    {:producer, {stack, continuation}, Keyword.take(opts, [:dispatcher, :demand])}
  end

  ### Addendum, shortcut to get stream synchronously as in functional code
  def next(pid \\ __MODULE__) do
    GenServer.call(pid, :next)
  end

  def handle_call(:next, _from, {stack, continuation}) when is_atom(continuation) do
    # nothing produced, returns nil in this case...
    {:reply, nil, {stack, continuation}}
  end

  def handle_call(:next, _from, {stack, continuation}) do
    # Ref: https://hexdocs.pm/gen_stage/GenStage.html#c:handle_call/3
    # we immediately return the result of the computation,
    # but we also set it to be dispatch as an event (other subscribers ?),
    # just as a demand of 1 would have.
    case continuation.({:cont, {[], 1}}) do
      {:suspended, {[], 0}, continuation} ->
        {:reply, nil, [], {stack, continuation}}

      {:suspended, {list, 0}, continuation} ->
        {:reply, hd(list), :lists.reverse(list), {stack, continuation}}

      {status, {[], _}} ->
        GenStage.async_info(self(), :stop)
        {:reply, nil, [], {stack, status}}

      {status, {list, _}} ->
        GenStage.async_info(self(), :stop)
        {:reply, hd(list), :lists.reverse(list), {stack, status}}
    end
  end

  ###

  def handle_demand(_demand, {stack, continuation}) when is_atom(continuation) do
    {:noreply, [], {stack, continuation}}
  end

  def handle_demand(demand, {stack, continuation}) when demand > 0 do
    case continuation.({:cont, {[], demand}}) do
      {:suspended, {list, 0}, continuation} ->
        {:noreply, :lists.reverse(list), {stack, continuation}}

      {status, {list, _}} ->
        GenStage.async_info(self(), :stop)
        {:noreply, :lists.reverse(list), {stack, status}}
    end
  end

  def handle_info(:stop, state) do
    {:stop, :normal, state}
  end

  def handle_info(msg, {stack, continuation}) do
    log = '** Undefined handle_info in ~tp~n** Unhandled message: ~tp~n** Stream started at:~n~ts'
    :error_logger.warning_msg(log, [inspect(__MODULE__), msg, Exception.format_stacktrace(stack)])
    {:noreply, [], {stack, continuation}}
  end
end

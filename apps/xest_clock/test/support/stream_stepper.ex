defmodule XestClock.StreamStepper do
  # Designed from GenStage.Streamer
  @moduledoc """
  This is a GenServer holding a stream (designed from GenStage.Streamer as in Elixir 1.14)
    and setup so that a client process can ask for one element at a time, synchronously.
  We attempt to keep the same semantics, so the synchronous request will immediately trigger an event to be sent to all subscribers.
  """

  use GenServer

  def start_link(stream, opts \\ []) do
    GenServer.start_link(__MODULE__, stream, opts)
  end

  def take(pid \\ __MODULE__, demand) do
    GenServer.call(pid, {:take, demand})
  end

  @impl true
  def init(stream) do
    continuation =
      &Enumerable.reduce(stream, &1, fn
        x, {acc, 1} -> {:suspend, {[x | acc], 0}}
        x, {acc, counter} -> {:cont, {[x | acc], counter - 1}}
      end)

    {:ok, continuation}
  end

  @impl true
  def handle_call({:take, demand}, _from, continuation) when is_atom(continuation) do
    # nothing produced, returns nil in this case...
    {:reply, nil, continuation}
    # TODO: Shall we halt on nil ?? or keep it around ??
    # or maybe have a reset() that reuses the acc ??
    #  cf. gen_stage.streamer module for ideas...
  end

  @impl true
  def handle_call({:take, demand}, _from, continuation) do
    # Ref: https://hexdocs.pm/gen_stage/GenStage.html#c:handle_call/3
    # we immediately return the result of the computation,
    # but we also set it to be dispatch as an event (other subscribers ?),
    # just as a demand of 1 would have.
    case continuation.({:cont, {[], demand}}) do
      {:suspended, {list, 0}, continuation} ->
        {:reply, :lists.reverse(list), continuation}

      {status, {list, _}} ->
        {:reply, :lists.reverse(list), status}
    end
  end
end

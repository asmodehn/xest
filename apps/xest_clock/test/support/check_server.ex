defmodule XestClock.CheckServer do
  @docmodule """
    A simple genserver module, useful to automatically check memory consumption of some function call
  """

  use GenServer

  # Client
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def next(pid \\ __MODULE__) do
    GenServer.call(pid, :next)
  end

  def info(pid \\ __MODULE__) do
    GenServer.call(pid, :info)
  end

  # Callbacks
  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_call(:next, _from, generator) do
    {:reply, generator.(), generator}
  end

  @impl true
  def handle_call(:info, _from, generator) do
    # forcing garbage collect before info
    :erlang.garbage_collect(self())
    {:reply, Process.info(self()), generator}
  end
end

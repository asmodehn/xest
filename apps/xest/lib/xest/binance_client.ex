defmodule Xest.BinanceClient do
  use GenServer

  @doc """
  Starts reliable binance client.
  pass test_pid for the genserver to have access to the caller process
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, {:ok}, opts)
  end

  def system_status(pid \\ __MODULE__) do
    GenServer.call(pid, {:system_status})
  end

  def time(pid \\ __MODULE__) do
    GenServer.call(pid, {:time})
  end

  ## Defining GenServer Callbacks
  @impl true
  def init({:ok}) do
    binance_client_adapter = Application.get_env(:xest, :binance_client_adapter)
    # TMP no state for now, except the adapter for dynamic dispatch
    # => lets try to manage everything with tesla...
    {:ok, %{binance_client_adapter: binance_client_adapter}}
  end

  @impl true
  def handle_call({:system_status}, _from, %{binance_client_adapter: binance_client_adapter} = state) do
    {:reply, binance_client_adapter.system_status(), state}
  end

  @impl true
  def handle_call({:time}, _from, %{binance_client_adapter: binance_client_adapter} = state) do
    {:reply, binance_client_adapter.time(), state}
  end
end

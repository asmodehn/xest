defmodule XestWeb.ClockLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <div class="text-3xl font-bold underline">
      <h2>It's <%= Calendar.strftime(@date, "%H:%M:%S") %></h2>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok, _} = :timer.send_interval(1000, self(), :tick)
    end

    {:ok, put_date(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  def handle_event("nav", _path, socket) do
    {:noreply, socket}
  end

  defp put_date(socket) do
    assign(socket, date: NaiveDateTime.local_now())
  end
end

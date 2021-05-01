defmodule Xest.TUI.TUI do
  @behaviour Ratatouille.App

  alias Ratatouille.{EventManager, Window}
  alias Ratatouille.Runtime.{Subscription, State}

  require DateTime
  import Ratatouille.View

  alias Xest.BinanceExchange
  alias Xest.Models

  @impl true
  def init(_context) do
    {DateTime.utc_now(), 0, Xest.BinanceExchange.model(Xest.BinanceExchange)}
  end

  @impl true
  def subscribe(_model) do
    Subscription.interval(1_000, :tick)
  end

  @impl true
  def update({now, counter, exchange}, msg) do
    case msg do
      {:event, %{ch: ?q}} ->
        :ok = Window.close()

      {:event, %{ch: ?+}} ->
        {now, counter + 1, exchange}

      {:event, %{ch: ?-}} ->
        {now, counter - 1, exchange}

      :tick ->
        {DateTime.utc_now(), counter, exchange}

      _ ->
        IO.inspect(msg)
        {now, counter, exchange}
    end
  end

  # TODO : TUI design...

  # Various windows:
  # - HTTP requests (a nice log view)
  # - websockets (a nice log view)
  # - Events (from both rest polling and websockets, a debugging interface for commanded)
  # - Exchange (model) State (from Events, but other untracked sources) - default view

  @impl true
  def render({now, counter, exchange}) do
    view do
      panel title: "Clock Example ('q' to quit)" do
        label(content: "The time is: #{DateTime.to_string(now)}")
      end

      panel title: "Counter" do
        label(content: "Counter is #{counter} (+/-)")
      end

      render_exchange(exchange)
    end
  end

  defp render_exchange(%Models.Exchange{} = exchange) do
    panel title: "Exchange" do
      label(content: "code: #{exchange.status.code} ")
      label(content: "status: #{exchange.status.message} ")
    end
  end

  defp render_events() do
  end

  defp render_adapters() do
  end
end

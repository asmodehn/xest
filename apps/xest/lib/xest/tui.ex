defmodule Xest.TUI do
  @behaviour Ratatouille.App

  alias Ratatouille.{EventManager, Window}
  alias Ratatouille.Runtime.{Subscription, State}

  require DateTime
  import Ratatouille.View

  @impl true
  def init(_context) do
    {DateTime.utc_now(), 0}
  end

  @impl true
  def subscribe(_model) do
    Subscription.interval(1_000, :tick)
  end

  @impl true
  def update({now, counter}, msg) do
    case msg do
      {:event, %{ch: ?q}} ->
        :ok = Window.close()

      {:event, %{ch: ?+}} ->
        {now, counter + 1}

      {:event, %{ch: ?-}} ->
        {now, counter - 1}

      :tick ->
        {DateTime.utc_now(), counter}

      _ ->
        IO.inspect(msg)
        {now, counter}
    end
  end

  @impl true
  def render({now, counter}) do
    view do
      panel title: "Clock Example ('q' to quit)" do
        label(content: "The time is: #{DateTime.to_string(now)}")
      end

      panel title: "Counter" do
        label(content: "Counter is #{counter} (+/-)")
      end
    end
  end
end

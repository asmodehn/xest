defmodule XestWeb.StatusLiveTest do
  @moduledoc """
  To run only some tests:
    mix test apps/xest_web/test/xest_web/live/status_live_test.exs --only describe:binance
  """

  use XestWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Xest.Exchange
  alias Xest.Clock

  import Hammox

  @time_stop ~U[2021-02-18 08:53:32.313Z]

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "none" do
    test "- disconnected and connected render", %{conn: conn} do
      # no exchange setup for this call
      Clock.Mock
      |> expect(:utc_now, fn -> @time_stop end)

      conn = get(conn, "/status")
      html = html_response(conn, 200)
      assert html =~ "Hello ?? !"

      Clock.Mock
      |> expect(:utc_now, fn -> @time_stop end)

      # no exchange setup for this call
      Clock.Mock
      |> expect(:utc_now, fn -> @time_stop end)

      {:ok, _view, html} = live(conn, "/status")
      assert html =~ "Hello ?? !"
      assert html =~ "Status: N/A"
      assert html =~ "08:53:32"
    end
  end

  describe "unknown" do
    test "- disconnected and connected render", %{conn: conn} do
      Clock.Mock
      |> expect(:utc_now, fn -> @time_stop end)

      conn = get(conn, "/status/unknown")
      html = html_response(conn, 302)

      assert html =~ "<a href=\"/status\">redirected</a>"

      # no exchange setup for this call (only one clock call before redirect)
      Clock.Mock
      |> expect(:utc_now, fn -> @time_stop end)

      {:error, {:redirect, %{flash: flash_msg, to: "/status"}}} = live(conn, "/status/unknown")

      # TODO: something like assert get_flash(conn, :error) == "unknown is not a supported exchange"
    end
  end

  describe "binance" do
    test "- disconnected and connected render", %{conn: conn} do
      Exchange.Mock
      |> expect(:status, fn :binance -> %Exchange.Status{status: :online, description: "test"} end)

      # no exchange setup for this call
      Clock.Mock
      |> expect(:utc_now, fn -> @time_stop end)

      conn = get(conn, "/status/binance")

      html = html_response(conn, 200)
      assert html =~ "Hello binance !"
      assert html =~ "Status: N/A"
      assert html =~ "08:53:32"

      # Once clock without exchange (local) once with exchange
      Clock.Mock
      |> expect(:utc_now, fn -> @time_stop end)

      Clock.Mock
      |> expect(:utc_now, fn :binance -> @time_stop end)

      {:ok, _view, html} = live(conn, "/status/binance")

      # after websocket connection, message changed
      assert html =~ "Hello binance !"
      assert html =~ "Status: test"
      assert html =~ "08:53:32"
    end

    test "- sending a message to the liveview process displays it in flash view", %{
      conn: conn
    } do
      Exchange.Mock
      |> expect(:status, fn :binance -> %Exchange.Status{status: :online, description: "test"} end)

      Clock.Mock
      |> expect(:utc_now, fn -> @time_stop end)

      Clock.Mock
      |> expect(:utc_now, fn :binance -> @time_stop end)

      {:ok, view, _html} = live(conn, "/status/binance")

      send(view.pid, "Test Info Message")
      assert render(view) =~ "Test Info Message"
    end
  end

  describe "kraken" do
    test "disconnected and connected render", %{conn: conn} do
      Exchange.Mock
      |> expect(:status, fn :kraken -> %Exchange.Status{description: "test"} end)

      # Once clock without exchange (local) once with exchange
      Clock.Mock
      |> expect(:utc_now, fn -> @time_stop end)

      conn = get(conn, "/status/kraken")

      html = html_response(conn, 200)
      assert html =~ "Hello kraken !"
      assert html =~ "Status: N/A"
      assert html =~ "08:53:32"

      # Once clock without exchange (local) once with exchange
      Clock.Mock
      |> expect(:utc_now, fn -> @time_stop end)

      Clock.Mock
      |> expect(:utc_now, fn :kraken -> ~U[2020-02-02 02:02:02.020Z] end)

      {:ok, _view, html} = live(conn, "/status/kraken")

      # after websocket connection, message changed
      assert html =~ "Hello kraken !"
      assert html =~ "Status: test"
      assert html =~ "02:02:02"
    end

    test "sending a message to the liveview process displays it in flash view", %{
      conn: conn
    } do
      Exchange.Mock
      |> expect(:status, fn :kraken -> %Exchange.Status{description: "test"} end)

      # Once clock without exchange (local) once with exchange
      Clock.Mock
      |> expect(:utc_now, fn -> @time_stop end)

      Clock.Mock
      |> expect(:utc_now, fn :kraken -> ~U[2020-02-02 02:02:02.020Z] end)

      {:ok, view, _html} = live(conn, "/status/kraken")

      send(view.pid, "Test Info Message")
      assert render(view) =~ "Test Info Message"
    end
  end
end

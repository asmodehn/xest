defmodule XestWeb.TradesLiveTest do
  use XestWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Xest.Account

  import Hammox

  @time_stop ~U[2021-02-18 08:53:32.313Z]

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "binance" do
    # TODO : gather test setup in describe scope

    test "disconnected and connected render", %{conn: conn} do
      Account.Mock
      |> expect(:transactions, fn :binance, "SYMBOLA" ->
        %Account.TradesHistory{
          history: %{
            "ID-0001" => %Account.Trade{
              pair: "SYMBOLA",
              price: 123.456,
              time: 123.456,
              vol: 1.23
            }
          }
        }
      end)

      conn = get(conn, "/trades/binance/SYMBOLA")

      html = html_response(conn, 200)
      refute html =~ "ID-0001"

      {:ok, _view, html} = live(conn, "/trades/binance/SYMBOLA")
      # after websocket connection, message changed
      assert html =~
               "<tr><td>ID-0001</td><td>SYMBOLA</td><td>123.456</td><td>123.456</td><td>1.23</td></tr>"
    end

    test "sending a message to the liveview process displays it in flash view", %{
      conn: conn
    } do
      Account.Mock
      |> expect(:transactions, fn :binance, "SYMBOLA" ->
        %Account.TradesHistory{
          history: %{
            "ID-0001" => %Account.Trade{
              pair: "SYMBOLA",
              price: 123.456,
              time: 123.456,
              vol: 1.23
            }
          }
        }
      end)

      {:ok, view, _html} = live(conn, "/trades/binance/SYMBOLA")

      send(view.pid, "Test Info Message")
      assert render(view) =~ "Test Info Message"
    end
  end

  describe "kraken" do
    test "disconnected and connected render", %{conn: conn} do
      Account.Mock
      |> expect(:transactions, fn :kraken, "SYMBOLA" ->
        %Account.TradesHistory{
          history: %{
            "ID-0001" => %Account.Trade{
              pair: "SYMBOLA",
              price: 123.456,
              time: 123.456,
              vol: 1.23
            }
          }
        }
      end)

      conn = get(conn, "/trades/kraken/SYMBOLA")

      html = html_response(conn, 200)
      refute html =~ "ID-0001"

      {:ok, _view, html} = live(conn, "/trades/kraken/SYMBOLA")
      # after websocket connection, message changed
      assert html =~
               "<tr><td>ID-0001</td><td>SYMBOLA</td><td>123.456</td><td>123.456</td><td>1.23</td></tr>"
    end

    test "sending a message to the liveview process displays it in flash view", %{
      conn: conn
    } do
      Account.Mock
      |> expect(:transactions, fn :kraken, "SYMBOLA" ->
        %Account.TradesHistory{
          history: %{
            "ID-0001" => %Account.Trade{
              pair: "SYMBOLA",
              price: 123.456,
              time: 123.456,
              vol: 1.23
            }
          }
        }
      end)

      {:ok, view, _html} = live(conn, "/trades/kraken/SYMBOLA")

      send(view.pid, "Test Info Message")
      assert render(view) =~ "Test Info Message"
    end
  end
end

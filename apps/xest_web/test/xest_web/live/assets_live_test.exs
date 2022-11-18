defmodule XestWeb.AssetsLiveTest do
  use XestWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Xest.Exchange
  alias Xest.Account

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "binance" do
    test "disconnected and connected render", %{conn: conn} do
      Exchange.Mock
      |> expect(:symbols, 1, fn :binance -> ["BTCEUR", "ETHBTC"] end)

      # called a second time for symbols
      Account.Mock
      |> expect(:balance, 2, fn :binance ->
        %Account.Balance{
          balances: [%Account.AssetBalance{asset: "BTC", free: "1.23", locked: "4.56"}]
        }
      end)

      conn = get(conn, "/assets/binance")

      html = html_response(conn, 200)
      refute html =~ "BTC"

      {:ok, _view, html} = live(conn, "/assets/binance")

      # after websocket connection, message changed
      assert html =~ "BTC 1.23 (Locked: 4.56)"
    end

    test "sending a message to the liveview process displays it in flash view", %{
      conn: conn
    } do
      Exchange.Mock
      |> expect(:symbols, 1, fn :binance -> ["BTCEUR", "ETHBTC"] end)

      # called a second time for symbols
      Account.Mock
      |> expect(:balance, 2, fn :binance ->
        %Account.Balance{
          balances: [%Account.AssetBalance{asset: "BTC", free: "1.23", locked: "4.56"}]
        }
      end)

      {:ok, view, _html} = live(conn, "/assets/binance")

      send(view.pid, "Test Info Message")
      assert render(view) =~ "Test Info Message"
    end
  end

  describe "kraken" do
    test "disconnected and connected render", %{conn: conn} do
      Exchange.Mock
      |> expect(:symbols, 3, fn :kraken -> ["XXBTZEUR", "XETHXXBT"] end)

      # called a second time for symbols
      Account.Mock
      |> expect(:balance, 2, fn :kraken ->
        %Account.Balance{
          balances: [
            %Account.AssetBalance{
              asset: "ZEUR",
              free: "100.0000"
            },
            %Account.AssetBalance{
              asset: "XETH",
              free: "0.1000000000"
            },
            %Account.AssetBalance{
              asset: "XXBT",
              free: "0.0100000000"
            }
          ]
        }
      end)

      conn = get(conn, "/assets/kraken")

      html = html_response(conn, 200)
      refute html =~ "XXBT"

      {:ok, _view, html} = live(conn, "/assets/kraken")

      # after websocket connection, message changed
      assert html =~ "XXBT 0.0100000000 (Locked: 0.0)"
    end

    test "sending a message to the liveview process displays it in flash view", %{
      conn: conn
    } do
      Exchange.Mock
      |> expect(:symbols, 3, fn :kraken -> ["XXBTZEUR", "XETHXXBT"] end)

      Account.Mock
      |> expect(:balance, 2, fn :kraken ->
        %Account.Balance{
          balances: [
            %Account.AssetBalance{
              asset: "ZEUR",
              free: "100.0000"
            },
            %Account.AssetBalance{
              asset: "XETH",
              free: "0.1000000000"
            },
            %Account.AssetBalance{
              asset: "XXBT",
              free: "0.0100000000"
            }
          ]
        }
      end)

      {:ok, view, _html} = live(conn, "/assets/kraken")

      send(view.pid, "Test Info Message")
      assert render(view) =~ "Test Info Message"
    end
  end
end

defmodule XestKraken.Adapter.Krakex.Test.Integration do
  @moduledoc """
    This test module holds:
    - tests against a public interface of a real server
    - recorded tests against a private interface
  """

  use ExUnit.Case, async: false

  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: XestKraken.Adapter, behaviour: XestKraken.Adapter.Behaviour

  setup_all do
    HTTPoison.start()
  end

  use FlowAssertions

  @tag :integration
  @tag private: false
  test "system status OK" do
    client = XestKraken.Adapter.Client.new()

    XestKraken.Adapter.Krakex.system_status(client)
    |> ok_content
    |> assert_fields([:status, :timestamp])
  end

  @tag :integration
  @tag private: false
  test "servertime OK" do
    client = XestKraken.Adapter.Client.new()

    XestKraken.Adapter.Krakex.servertime(client)
    |> ok_content
    |> assert_fields([:rfc1123, :unixtime])
  end

  describe "with configured api_key, secret and endpoint" do
    setup do
      # getting config as application would do
      # user's config file should be overridden before test is run
      # in test_helper.ex
      config = Vapor.load!(XestKraken.Config)

      client_state =
        XestKraken.Adapter.Client.new(
          config.xest_kraken.apikey,
          config.xest_kraken.secret,
          config.xest_kraken.endpoint
        )

      %{client_state: client_state}
    end

    @tag private: true
    test "balances OK", %{client_state: client_state} do
      use_cassette "balances_ok" do
        ExVCR.Config.filter_request_headers("Api-Key")
        ExVCR.Config.filter_request_headers("Api-Sign")
        {:ok, balance} = XestKraken.Adapter.Krakex.balance(client_state)

        # match balance struct...
        %{"XETH" => "0.1000000000", "XXBT" => "0.0100000000", "ZEUR" => "100.0000"} = balance
      end
    end

    @tag private: true
    test "balances BAD", %{client_state: client_state} do
      use_cassette "balances_bad" do
        ExVCR.Config.filter_request_headers("Api-Sign")
        {:error, reason} = XestKraken.Adapter.Krakex.balance(client_state)

        assert reason == "EAPI:Invalid key"
      end
    end

    @tag private: true
    test "trades OK", %{client_state: client_state} do
      use_cassette "trades_ok" do
        ExVCR.Config.filter_request_headers("Api-Key")
        ExVCR.Config.filter_request_headers("Api-Sign")
        {:ok, trades} = XestKraken.Adapter.Krakex.trades(client_state)

        # match trades struct...
        %{
          "count" => 2,
          "trades" => %{
            "TCHZBK-A4PQE-BU67OY" => %{
              "cost" => "900.00000",
              "fee" => "1.200",
              "margin" => "0.00000",
              "misc" => "",
              "ordertxid" => "OJ63SQ-H7DIP-SZVPS7",
              "ordertype" => "limit",
              "pair" => "DOTEUR",
              "postxid" => "TKQ3SE-Y7SF5-ZFI7LT",
              "price" => "30.00000",
              "time" => 1_634_144_450.2543,
              "type" => "sell",
              "vol" => "23.40000000"
            }
          }
        } = trades
      end
    end

    @tag private: true
    test "trades BAD", %{client_state: client_state} do
      use_cassette "trades_bad" do
        ExVCR.Config.filter_request_headers("Api-Sign")
        {:error, reason} = XestKraken.Adapter.Krakex.trades(client_state)

        assert reason == "EAPI:Invalid key"
      end
    end
  end
end

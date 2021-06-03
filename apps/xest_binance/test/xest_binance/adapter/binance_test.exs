defmodule XestBinance.Binance.Test do
  use ExUnit.Case, async: true

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  import Hammox

  use Hammox.Protect,
    module: XestBinance.Adapter.Binance,
    behaviour: XestBinance.Adapter.Behaviour

  setup :verify_on_exit!

  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    HTTPoison.start()
  end

  test "system status OK" do
    use_cassette "systemstatus_ok" do
      assert XestBinance.Adapter.Client.new()
             |> XestBinance.Adapter.Binance.system_status() ==
               {:ok, %Binance.SystemStatus{status: 0, msg: "normal"}}
    end
  end

  test "ping OK" do
    use_cassette "ping_ok" do
      assert XestBinance.Adapter.Client.new()
             |> XestBinance.Adapter.Binance.ping() == {:ok, %{}}
    end
  end

  test "time OK" do
    use_cassette "servertime_ok" do
      assert XestBinance.Adapter.Client.new()
             |> XestBinance.Adapter.Binance.servertime() == {:ok, ~U[2021-05-14 09:31:37.108Z]}
    end
  end

  describe "without api_key and secret key" do
    setup do
      client_state = XestBinance.Adapter.Client.new(nil, nil)
      %{client_state: client_state}
    end

    test "api key missing error returned", %{client_state: client_state} do
      {:error, reason} = XestBinance.Adapter.Binance.account(client_state)
      assert reason == {:config_missing, "Secret and API key missing"}
    end
  end

  describe "with invalid api_key and secret key" do
    setup do
      client_state = XestBinance.Adapter.Client.new("Bad Key", "Bad Secret")
      %{client_state: client_state}
    end

    test "APIkey invalid error returned", %{client_state: client_state} do
      {:error, reason} = XestBinance.Adapter.Binance.account(client_state)
      assert reason == %{"code" => -2014, "msg" => "API-key format invalid."}
    end
  end

  describe "with configured api_key, secret and endpoint" do
    @describetag :integration
    setup do
      # getting config as application would do
      # WARNING this will retrieve your actual account
      config = Vapor.load!(XestBinance.Config)

      client_state =
        XestBinance.Adapter.Client.new(
          config.binance.apikey,
          config.binance.secret,
          config.binance.endpoint
        )

      %{client_state: client_state}
    end

    test "account OK", %{client_state: client_state} do
      use_cassette "account_ok" do
        ExVCR.Config.filter_request_headers("X-MBX-APIKEY")
        ExVCR.Config.filter_sensitive_data("signature=[a-zA-Z0-9]*", "signature=***")
        {:ok, account} = XestBinance.Adapter.Binance.account(client_state)

        # match account struct...
        %Binance.Account{
          balances: _balances,
          buyer_commission: _buyer_commission,
          can_deposit: _can_deposit,
          can_trade: _can_trade,
          can_withdrawl: _can_withdrawl,
          maker_commission: _maker_commission,
          seller_commission: _seller_commission,
          taker_commission: _taker_commission,
          update_time: _update_time
        } = account
      end
    end
  end
end

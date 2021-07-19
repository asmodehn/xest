defmodule XestBinance.Binance.Test.Integration do
  use ExUnit.Case, async: false

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

  describe "with configured api_key, secret and endpoint" do
    setup do
      # getting config as application would do
      # WARNING this will retrieve your actual account
      config = Vapor.load!(XestBinance.Config)

      client_state =
        XestBinance.Adapter.Client.new(
          config.xest_binance.apikey,
          config.xest_binance.secret,
          config.xest_binance.endpoint
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

    test "account BAD", %{client_state: client_state} do
      use_cassette "account_bad" do
        ExVCR.Config.filter_sensitive_data("signature=[a-zA-Z0-9]*", "signature=***")

        {:error, reason} = XestBinance.Adapter.Binance.account(client_state)

        assert reason == %{
                 "code" => -2015,
                 "msg" => "Invalid API-key, IP, or permissions for action."
               }
      end
    end
  end
end

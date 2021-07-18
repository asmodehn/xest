defmodule XestKraken.Adapter.Krakex.Test.Integration do
  use ExUnit.Case, async: false

  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: XestKraken.Adapter, behaviour: XestKraken.Adapter.Behaviour

  setup_all do
    HTTPoison.start()
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

    test "balances OK", %{client_state: client_state} do
      use_cassette "balances_ok" do
        ExVCR.Config.filter_request_headers("Api-Key")
        ExVCR.Config.filter_request_headers("Api-Sign")
        {:ok, account} = XestKraken.Adapter.Krakex.balance(client_state)

        # match balance struct...
        %{"XETH" => "0.1000000000", "XXBT" => "0.0100000000", "ZEUR" => "100.0000"} = account
      end
    end

    test "balances BAD", %{client_state: client_state} do
      use_cassette "balances_bad" do
        ExVCR.Config.filter_request_headers("Api-Key")
        {:error, reason} = XestKraken.Adapter.Krakex.balance(client_state)

        assert reason == "EAPI:Invalid key"
      end
    end
  end
end

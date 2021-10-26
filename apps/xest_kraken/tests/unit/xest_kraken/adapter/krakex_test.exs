defmodule XestKraken.Adapter.Krakex.Test do
  use ExUnit.Case, async: true

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  import Hammox

  use Hammox.Protect, module: XestKraken.Adapter, behaviour: XestKraken.Adapter.Behaviour

  setup :verify_on_exit!

  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    HTTPoison.start()
  end

  # TODO: also test integration here (server down, etc.)

  test "system status OK" do
    use_cassette "systemstatus_ok" do
      client = XestKraken.Adapter.Client.new()

      assert XestKraken.Adapter.Krakex.system_status(client) ==
               {:ok,
                %{
                  status: "online",
                  timestamp: ~U[2021-05-31T08:50:01Z]
                }}
    end
  end

  test "servertime OK" do
    use_cassette "servertime_ok" do
      client = XestKraken.Adapter.Client.new()

      assert XestKraken.Adapter.Krakex.servertime(client) ==
               {:ok,
                %{
                  rfc1123: "Thu,  3 Jun 21 12:36:38 +0000",
                  unixtime: ~U[2021-06-03 12:36:38Z]
                }}
    end
  end

  describe "without api_key and secret key" do
    setup do
      client_state = XestKraken.Adapter.Client.new(nil, nil)
      %{client_state: client_state}
    end

    test "MissingCredentialsError is raised", %{client_state: client_state} do
      assert_raise Krakex.API.MissingCredentialsError, fn ->
        XestKraken.Adapter.Krakex.balance(client_state)
      end
    end
  end

  test "with invalid api_key and secret key, Runtime Error is raised on client creation" do
    assert_raise RuntimeError, fn ->
      XestKraken.Adapter.Client.new("Bad Key", "Bad Secret")
    end
  end

  describe "with configured api_key, secret and endpoint" do
    setup do
      # getting config as application would do
      # WARNING this will retrieve your actual account
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

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
      use_cassette "invalid_key" do
        ExVCR.Config.filter_sensitive_data("signature=[a-zA-Z0-9]*", "signature=***")

        {:error, reason} = XestBinance.Adapter.Binance.account(client_state)

        assert reason == %{"code" => -2014, "msg" => "API-key format invalid."}
      end
    end
  end
end

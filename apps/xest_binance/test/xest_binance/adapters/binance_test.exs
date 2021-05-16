defmodule XestBinance.Binance.Test do
  use ExUnit.Case, async: true

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  import Hammox

  use Hammox.Protect,
    module: XestBinance.Client,
    behaviour: XestBinance.Ports.ClientBehaviour

  setup :verify_on_exit!

  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    HTTPoison.start()
  end

  test "system status OK" do
    use_cassette "systemstatus_ok" do
      assert XestBinance.Client.system_status() ==
               {:ok, %XestBinance.Models.ExchangeStatus{code: 0, message: "normal"}}
    end
  end

  test "ping OK" do
    use_cassette "ping_ok" do
      assert XestBinance.Client.ping() == {:ok, %{}}
    end
  end

  test "time OK" do
    use_cassette "servertime_ok" do
      assert XestBinance.Client.time() == {:ok, ~U[2021-05-14 09:31:37.108Z]}
    end
  end

  describe "without api_key and secret key" do
    setup do
      # erasing keys for test

      apikey = Application.get_env(:binance, :api_key)
      secret = Application.get_env(:binance, :secret_key)

      Application.delete_env(:binance, :api_key)
      Application.delete_env(:binance, :secret_key)

      on_exit(fn ->
        Application.put_env(:binance, :api_key, apikey)
        Application.put_env(:binance, :secret_key, secret)
      end)
    end

    test "api key missing error returned" do
      {:error, reason} = XestBinance.Client.get_account()
      assert reason == {:config_missing, "Secret and API key missing"}
    end
  end

  describe "with invalid api_key and secret key" do
    setup do
      # erasing keys for test

      apikey = Application.get_env(:binance, :api_key)
      secret = Application.get_env(:binance, :secret_key)

      Application.put_env(:binance, :api_key, "Bad Key")
      Application.put_env(:binance, :secret_key, "Bad Secret")

      on_exit(fn ->
        Application.put_env(:binance, :api_key, apikey)
        Application.put_env(:binance, :secret_key, secret)
      end)
    end

    test "APIkey invalid error returned" do
      {:error, reason} = XestBinance.Client.get_account()
      assert reason == %{"code" => -2014, "msg" => "API-key format invalid."}
    end
  end

  @tag :integration
  test "account OK" do
    {:ok, account} = XestBinance.Client.get_account()

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

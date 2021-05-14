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
end

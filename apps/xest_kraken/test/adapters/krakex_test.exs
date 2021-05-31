defmodule XestKraken.Krakex.Test do
  use ExUnit.Case, async: true

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  import Hammox

  use Hammox.Protect,
    module: XestKraken.Krakex,
    behaviour: XestKraken.Ports.AdapterBehaviour

  setup :verify_on_exit!

  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    HTTPoison.start()
  end

  test "system status OK" do
    use_cassette "systemstatus_ok" do
      client = XestKraken.Krakex.new()
      IO.inspect(client)

      assert XestKraken.Krakex.system_status(client) ==
               {:ok, %{"status" => "online", "timestamp" => "2021-05-31T08:50:01Z"}}
    end
  end
end

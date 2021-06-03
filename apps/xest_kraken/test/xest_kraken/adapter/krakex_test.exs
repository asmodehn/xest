defmodule XestKraken.Adapter.Krakex.Test do
  use ExUnit.Case, async: true

  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: XestKraken.Adapter, behaviour: XestKraken.Adapter.Behaviour

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
end

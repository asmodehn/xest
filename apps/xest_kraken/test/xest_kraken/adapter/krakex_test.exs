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
                  "status" => "online",
                  "timestamp" => "2021-05-31T08:50:01Z"
                }}
    end
  end
end

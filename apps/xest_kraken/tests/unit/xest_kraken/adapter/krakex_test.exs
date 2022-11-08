defmodule XestKraken.Adapter.Krakex.Test do
  @moduledoc """
    This test module holds:
    - recorded tests against a public interface
    - various checks not involving external systems
  """
  use ExUnit.Case, async: true

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  import Hammox

  use Hammox.Protect, module: XestKraken.Adapter, behaviour: XestKraken.Adapter.Behaviour

  setup :verify_on_exit!

  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    HTTPoison.start()
  end

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
end

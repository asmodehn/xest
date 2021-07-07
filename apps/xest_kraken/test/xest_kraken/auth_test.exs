defmodule XestKraken.Auth.Test do
  use ExUnit.Case, async: false
  # integration tests in general don't support async
  # And should not run in parallel, because of the global mutable state known as "real world"

  use FlowAssertions

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect,
    module: XestKraken.Auth,
    behaviour: XestKraken.Auth.Behaviour

  # DESIGN : here we focus on testing the integration with a real HTTP server, implementing expectations from Docs
  # rather than from cassettes, as is done for the client.
  # This allows us to test rare behaviors, like errors, from specification/documentation.

  describe "By default" do
    @describetag :integration
    # Note : there is two kind of integrations
    #  - with machine environment (configuration)
    #  - with timers / with communicating processes
    setup do
      bypass = Bypass.open()

      # starts server test process
      auth =
        start_supervised!({
          XestKraken.Auth,
          # setup bypass to use as local webserver for binance endpoint
          # Fake Key
          # Fake Secret
          name: XestKraken.Auth.Test.Process,
          endpoint: "http://localhost:#{bypass.port}/",
          apikey: "",
          secret: ""
        })

      %{auth: auth, bypass: bypass}
    end

    test "provides balance", %{auth: auth, bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/0/private/Balance", fn conn ->
        # Ref : https://docs.kraken.com/rest/#operation/getAccountBalance
        Plug.Conn.resp(conn, 200, """
        {
          \"error\": [ ],
          \"result\":
          {
            \"ZEUR\": "100.0000",
            \"XXBT\": "0.0100000000",
            \"XETH\": "0.1000000000"
          }
        }
        """)
      end)

      assert XestKraken.Auth.balance(auth) ==
               {:ok,
                %XestKraken.Account.Balance{
                  balances: [
                    %XestKraken.Account.AssetBalance{
                      asset: "XETH",
                      amount: "0.1000000000"
                    },
                    %XestKraken.Account.AssetBalance{
                      asset: "XXBT",
                      amount: "0.0100000000"
                    },
                    %XestKraken.Account.AssetBalance{
                      asset: "ZEUR",
                      amount: "100.0000"
                    }
                  ]
                }}
    end
  end
end

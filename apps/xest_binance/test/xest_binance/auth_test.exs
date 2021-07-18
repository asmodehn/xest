defmodule XestBinance.Authenticated.Test do
  use ExUnit.Case, async: false
  # integration tests in general don't support async
  # And should not run in parallel, because of the global mutable state known as "real world"

  use FlowAssertions

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect,
    module: XestBinance.Auth,
    behaviour: XestBinance.Auth.Behaviour

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
      server_pid =
        start_supervised!({
          XestBinance.Auth,
          # setup bypass to use as local webserver for binance endpoint
          # Fake Key
          # Fake Secret
          name: XestBinance.Auth.Test.Process,
          endpoint: "http://localhost:#{bypass.port}/",
          apikey: "",
          secret: ""
        })

      %{server_pid: server_pid, bypass: bypass}
    end

    test "provides account", %{server_pid: server_pid, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/api/v3/account", fn conn ->
        Plug.Conn.resp(conn, 200, """
        {
          "makerCommission": 15,
          "takerCommission": 15,
          "buyerCommission": 0,
          "sellerCommission": 0,
          "canTrade": true,
          "canWithdraw": true,
          "canDeposit": true,
          "updateTime": 123456789,
          "accountType": "SPOT",
          "balances": [
            {
              "asset": "BTC",
              "free": "4723846.89208129",
              "locked": "0.00000000"
            },
            {
              "asset": "LTC",
              "free": "4763368.68006011",
              "locked": "0.00000000"
            }
          ],
          "permissions": [
            "SPOT"
          ]
        }
        """)
      end)

      assert XestBinance.Auth.account(server_pid) ==
               {:ok,
                %Binance.Account{
                  balances: [
                    %{"asset" => "BTC", "free" => "4723846.89208129", "locked" => "0.00000000"},
                    %{"asset" => "LTC", "free" => "4763368.68006011", "locked" => "0.00000000"}
                  ],
                  buyer_commission: 0,
                  can_deposit: true,
                  can_trade: true,
                  can_withdrawl: nil,
                  maker_commission: 15,
                  seller_commission: 0,
                  taker_commission: 15,
                  update_time: 123_456_789
                }}
    end
  end
end

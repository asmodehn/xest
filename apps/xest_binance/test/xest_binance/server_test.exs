defmodule XestBinance.Server.Test do
  use ExUnit.Case, async: false
  # integration tests in general don't support async
  # And should not run in parallel, because of the global mutable state known as "real world"

  use FlowAssertions

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: XestBinance.Server, behaviour: XestBinance.Ports.ServerBehaviour

  # DESIGN : here we focus on testing the integration with a real HTTP server, implementing expectations from Docs
  # rather than from cassettes, as is done for the client.
  # This allows us to test rare behaviors, like errors, from specification/documentation.

  describe "By default" do
    @describetag :integration
    setup do
      bypass = Bypass.open()
      # setup bypass to use as local webserver for binance endpoint
      Application.put_env(:binance, :end_point, "http://localhost:#{bypass.port}/")

      # starts server test process
      server_pid =
        start_supervised!({
          XestBinance.Server,
          name: XestBinance.Server.Test.Process
        })

      %{server_pid: server_pid, bypass: bypass}
    end

    test "provides system status", %{server_pid: server_pid, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/wapi/v3/systemStatus.html", fn conn ->
        Plug.Conn.resp(conn, 200, """
        {
            "status": 0,
            "msg": "normal"
        }
        """)
      end)

      assert system_status(server_pid) ==
               {:ok, %XestBinance.Models.ExchangeStatus{message: "normal", code: 0}}
    end

    test "provides time", %{server_pid: server_pid, bypass: bypass} do
      udt = ~U[2021-02-18 08:53:32.313Z]

      Bypass.expect_once(bypass, "GET", "/api/v3/time", fn conn ->
        Plug.Conn.resp(conn, 200, """
        {
          "serverTime": #{DateTime.to_unix(udt, :millisecond)}
        }
        """)
      end)

      assert time(server_pid) == {:ok, udt}
    end

    # TODO: test to document default ping behavior
  end

  describe "With custom ping period" do
    @describetag :integration

    setup do
      bypass = Bypass.open()
      # setup bypass to use as local webserver for binance endpoint
      Application.put_env(:binance, :end_point, "http://localhost:#{bypass.port}/")
      %{bypass: bypass}

      server_pid =
        start_supervised!(
          {XestBinance.Server, name: __MODULE__, next_ping_wait_time: :timer.seconds(1)}
        )

      %{server_pid: server_pid, bypass: bypass}
    end

    test "provides read access to the next ping period", %{server_pid: server_pid} do
      %{
        next_ping_ref: _ping_timer,
        next_ping_wait_time: period
      } = XestBinance.Server.next_ping_schedule(server_pid)

      # TODO : is there a way to make this public (part of behaviour) somehow ?

      assert period == 1000
    end

    test "provides write access to the next ping period", %{server_pid: server_pid} do
      %{
        next_ping_ref: _ping_timer,
        next_ping_wait_time: period
      } = XestBinance.Server.next_ping_schedule(server_pid, :timer.seconds(0.5))

      assert period == 500
    end

    # tag for time related tests (should run with side-effect tests)
    @tag :timed
    test " ping happens in due time ", %{server_pid: _server_pid, bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/api/v3/ping", fn conn ->
        #        send(test_pid, :ping_done)

        Plug.Conn.resp(conn, 200, """
        {}
        """)
      end)

      #      assert_receive :ping_done, :timer.seconds(1) * 2
      Process.sleep(:timer.seconds(1) * 2)
    end

    # TODO : test ping reschedule when other request happens...
  end
end

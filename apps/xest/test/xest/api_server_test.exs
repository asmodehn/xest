defmodule Xest.APIServer.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.APIServer

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox

  defmodule TestServer do
    @birthdate ~U[1970-01-02 12:34:56Z]

    use APIServer
    # The simplest APIServer Implementation
    @impl true
    def init(init_arg) do
      {:ok, init_arg}
    end

    # to be able to easily start a TestServer
    def start_link(opts) do
      # setup clock at birthdate
      # TODO : clock in opts to pass this from caller (test...)
      DateTimeMock
      |> expect(:utc_now, fn -> @birthdate end)

      APIServer.start_link(
        __MODULE__,
        {42},
        opts
      )
    end

    @impl true
    def mockable_impl() do
      # useful for testing this behaviour
      Application.get_env(:xest, :api_test_server, __MODULE__)
    end
  end

  @lifetime ~T[00:07:00]
  @valid_clock_time ~U[1970-01-02 12:37:56Z]
  @invalid_clock_time ~U[1970-01-02 12:44:56Z]
  @child_valid_clock_time ~U[1970-01-02 12:50:56Z]

  describe "Given time to cache" do
    setup do
      # starts server test process
      server_pid =
        start_supervised!({
          TestServer,
          name: Xest.APIServer.Test.TestServer, lifetime: @lifetime
        })

      # setting up adapter mock to test the chain :
      # APIServerClient -> GenServer messaging -> APIServerBehaviour / API
      # without relying on specific client implementation (tesla or another)
      TestServer.mockable_impl()
      |> allow(self(), server_pid)
      |> expect(:handle_cachemiss, fn _request, _from, state ->
        # we pass the internal state as a response
        {:reply, state, state}
      end)

      # because we need ot play with time here...
      DateTimeMock
      |> allow(self(), server_pid)

      %{server_pid: server_pid}
    end

    test "call cache the result for a while",
         %{server_pid: server_pid} do
      DateTimeMock
      # fetch clock
      |> expect(:utc_now, fn -> @valid_clock_time end)
      # put clock
      |> expect(:utc_now, fn -> @valid_clock_time end)

      state_as_response = APIServer.call(server_pid, {:some_request, "some_param"})
      assert state_as_response == {42}

      DateTimeMock
      # fetch clock
      |> expect(:utc_now, fn -> @valid_clock_time end)

      state_as_response = APIServer.call(server_pid, {:some_request, "some_param"})
      assert state_as_response == {42}
    end

    test "cache invalidates after lifetime", %{server_pid: server_pid} do
      DateTimeMock
      # fetch clock
      |> expect(:utc_now, fn -> @valid_clock_time end)
      # put clock
      |> expect(:utc_now, fn -> @valid_clock_time end)

      state_as_response = APIServer.call(server_pid, {:some_request, "some_param"})
      assert state_as_response == {42}

      TestServer.mockable_impl()
      |> expect(:handle_cachemiss, fn _request, _from, {val} = state ->
        # we pass the internal state as a response
        {:reply, {val + 9}, state}
      end)

      DateTimeMock
      # fetch clock
      |> expect(:utc_now, fn -> @invalid_clock_time end)
      # put clock
      |> expect(:utc_now, fn -> @child_valid_clock_time end)

      state_as_response = APIServer.call(server_pid, {:some_request, "some_param"})
      assert state_as_response == {51}
    end
  end
end

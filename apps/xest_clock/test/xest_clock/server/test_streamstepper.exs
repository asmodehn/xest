defmodule XestClock.StreamStepperTest do
  # TMP to prevent errors given the stateful gen_server
  use ExUnit.Case, async: false
  doctest XestClock.Server.StreamStepper

  alias XestClock.Server.StreamStepper

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  defmodule TestServer do
    use StreamStepper

    def start_link(stream, opts \\ []) do
      XestClock.Server.StreamStepper.start_link(__MODULE__, stream, opts)
    end
  end

  describe "generated child_spec" do
    test "works as expected" do
      assert TestServer.child_spec(42) == %{
               id: XestClock.StreamStepperTest.TestServer,
               start: {
                 XestClock.StreamStepperTest.TestServer,
                 :start_link,
                 [42]
               }
             }
    end

    test "is usable by test framework" do
      {:ok, _pid} = start_supervised({TestServer, Stream.repeatedly(fn -> 42 end)})
    end
  end

  describe "start_link" do
    test "works as expected" do
      {:ok, _pid} = StreamStepper.start_link(TestServer, Stream.repeatedly(fn -> 42 end))
    end
  end

  describe "init" do
    test "works as expected" do
      %StreamStepper{
        stream: stream,
        continuation: c,
        backstep: bs
      } = StreamStepper.init(Stream.repeatedly(fn -> 42 end))

      # valid stream
      assert stream |> Enum.take(2) == [42, 42]
      # usable continuation
      {:suspended, {[42, 42, 42], 0}, _next_cont} = c.({:cont, {[], 3}})
      # no tick yet
      assert bs == []
    end

    test "is setup as default via __using__" do
      {:ok,
       %StreamStepper{
         stream: stream,
         continuation: c,
         backstep: bs
       }} = TestServer.init(Stream.repeatedly(fn -> 42 end))

      # valid stream
      assert stream |> Enum.take(2) == [42, 42]
      # usable continuation
      {:suspended, {[42, 42, 42], 0}, _next_cont} = c.({:cont, {[], 3}})
      # no tick yet
      assert bs == []
    end
  end

  describe "ticks" do
    setup do
      srv = start_supervised!({TestServer, Stream.repeatedly(fn -> 42 end)})
      %{test_server: srv}
    end

    test "returns ticks from __using__ server", %{test_server: srv} do
      assert StreamStepper.ticks(srv, 3) == [42, 42, 42]
    end
  end
end

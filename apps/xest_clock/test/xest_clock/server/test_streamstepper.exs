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

  describe "child_spec" do
    test "works for streamstepper" do
      assert StreamStepper.child_spec(42) == %{
               id: StreamStepper,
               start: {
                 StreamStepper,
                 :start_link,
                 # Note we need the extra argument here to
                 [StreamStepper, 42]
               }
             }
    end

    test "works for a server using streamstepper" do
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
      :ok = stop_supervised(TestServer)
    end
  end

  describe "start_link" do
    test "starts a streamstepper" do
      stream = Stream.repeatedly(fn -> 42 end)

      {:ok, pid} = StreamStepper.start_link(StreamStepper, stream)
      GenServer.stop(pid)
    end

    test "starts a genserver using streamstepper" do
      {:ok, pid} = StreamStepper.start_link(TestServer, Stream.repeatedly(fn -> 42 end))
      GenServer.stop(pid)
    end
  end

  describe "init" do
    test "handles initializing a streamstepper" do
      {:ok,
       %StreamStepper{
         stream: stream,
         continuation: c,
         backstep: bs
       }} = StreamStepper.init(Stream.repeatedly(fn -> 42 end))

      # valid stream
      assert stream |> Enum.take(2) == [42, 42]
      # usable continuation
      {:suspended, {[42, 42, 42], 0}, _next_cont} = c.({:cont, {[], 3}})
      # no tick yet
      assert bs == []
    end

    test "handles initializing a genserver using streamstepper" do
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
      stream =
        Stream.unfold(5, fn
          0 -> nil
          n -> {n, n - 1}
        end)

      # Notice how the stream is implicitely "duplicated"/ independently used in two different stepper...
      # -> the "state" of the stream is not shared between processes.
      {:ok, spid} = start_supervised({StreamStepper, stream})
      {:ok, tpid} = start_supervised({TestServer, stream})
      %{stepper: spid, testsrv: tpid}
    end

    test "works as expected for a streamstepper", %{stepper: spid} do
      assert StreamStepper.ticks(spid, 2) == [5, 4]
    end

    test "works as expected for a server using streamstepper", %{testsrv: tpid} do
      assert StreamStepper.ticks(tpid, 2) == [5, 4]
    end
  end
end

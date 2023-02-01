defmodule ExampleServer do
  import Hammox

  use XestClock.Server
  # use will setup the correct streamclock for leveraging the `handle_remote_unix_time` callback
  # the unit passed as parameter will be sent to handle_remote_unix_time

  # Client code

  # already defined in macro. good or not ?
  @impl true
  def start_link(unit, opts \\ []) when is_list(opts) do
    XestClock.Server.start_link(__MODULE__, unit, opts)
  end

  @impl true
  def init(state) do
    # mocks expectations are needed since clock also tracks local time internally
    XestClock.System.ExtraMock
    |> expect(:native_time_unit, fn -> :nanosecond end)

    XestClock.System.OriginalMock
    # TODO: This should fail on exit: it is called only once !
    |> expect(:monotonic_time, 25, fn _ -> 42 end)
    |> expect(:time_offset, fn _ -> 0 end)

    # Note : the local timestamp calls these one time only.
    # other stream operator will rely on that timestamp

    XestClock.Process.OriginalMock
    # Note : since we tick faster than unit here, we need to mock sleep.
    |> expect(:sleep, 1, fn _ -> :ok end)

    # This is not of interest in tests, which is why it is quickly done here internally.
    # Otherwise see allowances to do it from another process:
    # https://hexdocs.pm/mox/Mox.html#module-explicit-allowances

    # TODO : verify mocks are not called too often !
    #      verify_on_exit!()  # this wants to be called from the test process...

    XestClock.Server.init(state, &handle_remote_unix_time/1)
  end

  def tick(pid \\ __MODULE__) do
    List.first(ticks(pid, 1))
  end

  @impl true
  def ticks(pid \\ __MODULE__, demand) do
    XestClock.Server.ticks(pid, demand)
  end

  ## Callbacks
  @impl true
  def handle_remote_unix_time(unit) do
    case unit do
      :second -> 42
      :millisecond -> 42_000
      :microsecond -> 42_000_000
      :nanosecond -> 42_000_000_000
      # default and parts per seconds
      pps -> 42 * pps
    end
  end
end

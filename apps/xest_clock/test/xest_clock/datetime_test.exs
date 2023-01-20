defmodule XestClock.DateTime.Test do
  use ExUnit.Case, async: true

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox

  # Importing and protecting our behavior implementation cf. https://github.com/msz/hammox
  use Hammox.Protect, module: XestClock.DateTime, behaviour: XestClock.DateTime.Behaviour

  # shadowing Elixir's original DateTime
  alias XestClock.DateTime

  setup do
    # saving XestClock.DateTime implementation
    previous_datetime = Application.get_env(:xest_clock, :datetime_module)
    # Setup XestClock.DateTime Mock for these tests
    Hammox.defmock(XestClock.DateTime.Mock,
      for: XestClock.DateTime.Behaviour
    )

    Application.put_env(:xest_clock, :datetime_module, XestClock.DateTime.Mock)

    on_exit(fn ->
      # restoring config
      Application.put_env(:xest_clock, :datetime_module, previous_datetime)
    end)
  end

  setup :verify_on_exit!

  test "DateTime.utc_now is mockable like any mock" do
    DateTime.Mock
    |> expect(:utc_now, fn -> ~U[1970-01-01 01:01:01Z] end)

    assert DateTime.utc_now() == ~U[1970-01-01 01:01:01Z]
  end
end

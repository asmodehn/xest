defmodule Xest.DateTime.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  require Xest.DateTime

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  test "verifying local clock mock" do
    Xest.DateTimeMock
    |> expect(:utc_now, fn ->
      ~U[2020-01-01 00:00:00.000001Z]
    end)

    utc_now_0 = Hammox.protect({Xest.DateTime, :utc_now, 0}, Xest.DateTimeBehaviour)
    assert utc_now_0.() == ~U[2020-01-01 00:00:00.000001Z]
  end
end

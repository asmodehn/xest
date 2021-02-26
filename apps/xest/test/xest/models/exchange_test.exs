defmodule Xest.Domain.Exchange.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Models.Exchange
  alias Xest.Models.ExchangeStatus

  test "test exchange status initial values" do
    %ExchangeStatus{}
    |> assert_fields(%{
      message: nil,
      code: nil
    })
  end

  test "test exchange initial values" do
    %Exchange{}
    |> assert_fields(%{
      status: %ExchangeStatus{},
      server_time_skew_usec: nil
    })
  end

  test "test exchange status update" do
    %Exchange{}
    |> Exchange.update(status: %ExchangeStatus{message: "testmsg", code: 42})
    |> assert_fields(%{
      status: %ExchangeStatus{message: "testmsg", code: 42}
    })
  end

  test "test servertime estimate" do
    srv_timeskew_usec =
      Timex.Duration.to_microseconds(Timex.Duration.from_time(~T[01:01:42.001001]))

    exg = %{%Exchange{} | server_time_skew_usec: srv_timeskew_usec}
    mock_utc_now = fn -> ~U[2020-01-01 00:00:00.000001Z] end
    assert Exchange.servertime(exg, mock_utc_now) == ~U[2020-01-01 01:01:42.001002Z]
  end

  test "test compute servertime skew" do
    srv_timeskew_usec =
      Timex.Duration.to_microseconds(Timex.Duration.from_time(~T[01:01:42.001001]))

    exg = %{%Exchange{} | server_time_skew_usec: srv_timeskew_usec}
    mock_utc_now = fn -> ~U[2020-01-01 00:00:00.000001Z] end
    new_server_time = ~U[2020-01-01 01:01:01.001002Z]

    expected_skew_usec =
      Timex.Duration.to_microseconds(Timex.Duration.from_time(~T[01:01:01.001001]))

    assert Exchange.compute_time_skew_usec(exg, new_server_time, mock_utc_now) ==
             expected_skew_usec
  end
end

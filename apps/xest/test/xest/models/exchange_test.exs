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
      server_time_skew: nil
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
    exg = %{%Exchange{} | server_time_skew: ~T[01:01:42.001001]}
    mock_utc_now = fn -> ~U[2020-01-01 00:00:00.000001Z] end
    assert Exchange.servertime(exg, mock_utc_now) == ~U[2020-01-01 01:01:42.001002Z]
  end

  test "test compute servertime skew" do
    exg = %{%Exchange{} | server_time_skew: ~T[01:01:42.001001]}
    mock_utc_now = fn -> ~U[2020-01-01 00:00:00.000001Z] end
    new_server_time = ~U[2020-01-01 01:01:01.000002Z]
    assert Exchange.compute_time_skew(exg, new_server_time, mock_utc_now) == ~T[01:01:01.000001]
  end
end

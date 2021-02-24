defmodule Xest.Domain.Exchange.Test do
  use ExUnit.Case, async: true
  use FlowAssertions

  alias Xest.Domain.Exchange

  test "test servertime" do
    exg = %{%Exchange{} | server_time_skew: ~T[01:01:42.001001]}
    mock_utc_now = fn -> ~U[2020-01-01 00:00:00.000001Z] end
    assert Exchange.servertime(exg, mock_utc_now) == ~U[2020-01-01 01:01:42.001002Z]
  end
end

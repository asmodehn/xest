defmodule XestKraken.ACL.Test do
  use ExUnit.Case
  doctest XestKraken

  alias XestKraken.ACL

  @compile_now DateTime.utc_now()

  test "to_xest convert normal system_status" do
    # TODO: generate data with norm (f.i) https://github.com/keathley/norm
    xest_status =
      XestKraken.Adapter.SystemStatus.new(%{"status" => "normal", "timestamp" => @compile_now})

    assert ACL.to_xest(xest_status) == %Xest.ExchangeStatus{
             status: 0,
             message: "normal"
           }
  end

  test "to_xest convert other system_status" do
    # TODO: generate data with norm (f.i) https://github.com/keathley/norm
    xest_status =
      XestKraken.Adapter.SystemStatus.new(%{
        "status" => "something_else",
        "timestamp" => @compile_now
      })

    assert ACL.to_xest(xest_status) == %Xest.ExchangeStatus{
             status: 1,
             message: "something_else"
           }
  end
end

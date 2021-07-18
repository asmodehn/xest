defmodule Xest.Exchange.Status.Test do
  use ExUnit.Case, async: true

  test "algebraic datatype works" do
    status_struct =
      Xest.Exchange.Status.new(
        :offline,
        "no response..."
      )

    %Xest.Exchange.Status{
      status: status,
      description: descr
    } = status_struct

    assert status == :offline
    assert descr == "no response..."
  end
end

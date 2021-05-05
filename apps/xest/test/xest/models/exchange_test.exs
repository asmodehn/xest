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

  test "test exchange model initial values" do
    %Exchange{}
    |> assert_fields(%{
      status: %ExchangeStatus{}
    })
  end

  test "test exchange status update" do
    %Exchange{}
    |> Exchange.update(status: %ExchangeStatus{message: "testmsg", code: 42})
    |> assert_fields(%{
      status: %ExchangeStatus{message: "testmsg", code: 42}
    })
  end
end

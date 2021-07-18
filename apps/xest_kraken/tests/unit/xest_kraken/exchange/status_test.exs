defmodule XestKraken.Exchange.Status.Test do
  use ExUnit.Case, async: true

  # TODO norm for property testing of models

  describe "implementation for Xest ACL" do
    test "works" do
      xest_model =
        %XestKraken.Exchange.Status{status: "online", timestamp: DateTime.utc_now()}
        |> Xest.Exchange.Status.ACL.new()

      assert xest_model == %Xest.Exchange.Status{
               status: :online,
               description: "online"
             }
    end
  end
end

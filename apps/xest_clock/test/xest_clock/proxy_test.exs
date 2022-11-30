defmodule XestClock.Proxy.Test do
  use ExUnit.Case
  doctest XestClock.Proxy

  alias XestClock.Proxy
  alias XestClock.Clock

  describe "Xestclock.Proxy" do
    test "new/1 does set remote but not offset" do
      clock = Clock.new(:testremote, :second, [1, 2, 3, 4, 5])

      assert Proxy.new(clock) == %Proxy{
               remote: clock,
               offset: nil
             }
    end

    test "compute_offset/2 does compute the offset as timestamp" do
      clock = Clock.new(:testremote, :second, [1, 2, 3, 4, 5])
      proxy = Proxy.new(clock)
      ref = Clock.new(:refclock, :second, [0, 1, 2, 3, 4, 5])

      assert Proxy.compute_offset(proxy, ref) == %Proxy{
               remote: clock,
               offset: %Clock.Timestamp{
                 origin: :testremote,
                 unit: :second,
                 ts: 1
               }
             }
    end
  end
end

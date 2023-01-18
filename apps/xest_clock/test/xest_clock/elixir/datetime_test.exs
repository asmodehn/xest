defmodule XestClock.NewWrapper.DateTime.Test do
  use ExUnit.Case, async: true
  doctest XestClock.NewWrapper.DateTime

  import Hammox

  use Hammox.Protect,
    module: XestClock.NewWrapper.DateTime,
    behaviour: XestClock.NewWrapper.DateTime.OriginalBehaviour

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "to_naive/1" do
    # TODO: pure -> use stub
  end

  describe "from_unix" do
    # TODO: pure -> use stub
  end

  describe "from_unix!" do
    # TODO: pure -> use stub
  end

  describe "utc_now/1" do
    # TODO: impure -> use mock and expect
  end
end

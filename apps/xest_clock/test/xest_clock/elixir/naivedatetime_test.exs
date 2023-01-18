defmodule XestClock.NaiveDateTime.Test do
  use ExUnit.Case, async: true
  doctest XestClock.NaiveDateTime

  import Hammox

  use Hammox.Protect,
    module: XestClock.NaiveDateTime,
    behaviour: XestClock.NaiveDateTime.OriginalBehaviour

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "utc_now/1" do
    # TODO: impure -> use mock and expect
  end
end

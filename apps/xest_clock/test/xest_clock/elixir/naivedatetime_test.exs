defmodule XestClock.NaiveDateTime.Test do
  use ExUnit.Case, async: true
  doctest XestClock.NaiveDateTime

  import Hammox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  describe "utc_now/1" do
    # TODO: impure -> use System mock and expect
  end
end

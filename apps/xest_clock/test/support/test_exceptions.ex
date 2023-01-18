defmodule XestClock.TestExceptions.Impure do
  defexception message: "This function is impure. use a Mock with expect() instead"
end

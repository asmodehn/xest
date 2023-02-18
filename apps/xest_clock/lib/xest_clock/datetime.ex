defmodule XestClock.DateTime do
  @moduledoc """
    This module stands for Timestamps (in the unix sense)
    directly encoded as elixir's DateTime struct
  """

  # This has been transferred from xest where it was a module mostly standalone.
  # TODO : integrate this better with the concepts here... how much of it is still useful ?

  # TODO : new version of this is in XestClock.NewWrapper.DateTime. It should replace this eventually.

  defmodule Behaviour do
    # This is mandatory to use in Algebraic types
    @callback new :: DateTime.t()

    # This is the most useful effectful function
    @callback utc_now :: DateTime.t()
  end

  @behaviour Behaviour

  # this is a type alias to DateTime.t()
  @type t() :: DateTime.t()

  @impl true
  def new() do
    # return epoch by default
    date_time().from_unix!(0)
  end

  @impl true
  def utc_now() do
    date_time().utc_now()
  end

  # TODO : put that as module tag, to lockit on compilation...
  # BUT we currently need it dynamic for some tests ?? or is it redundant with Hammox ??
  defp date_time(), do: Application.get_env(:xest_clock, :datetime_module, DateTime)
end

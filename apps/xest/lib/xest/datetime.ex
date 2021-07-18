defmodule Xest.DateTime do
  @moduledoc """
    This module stands for Timestamps (in the unix sense)
    directly encoded as elixir's DateTime struct
  """

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
  defp date_time(), do: Application.get_env(:xest, :datetime_module, DateTime)
end

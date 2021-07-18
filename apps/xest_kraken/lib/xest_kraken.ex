defmodule XestKraken do
  @moduledoc """
  Documentation for `XestKraken`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> XestKraken.hello()
      :world

  """
  def hello do
    :world
  end

  def exchange() do
    XestKraken.Exchange
  end

  def clock() do
    XestKraken.Clock
  end

  # only one account supported currently
  def account() do
    XestKraken.Account
  end
end

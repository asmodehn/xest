defmodule Xest do
  @moduledoc """
  Xest keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def answer do
    42
  end

  @doc """
  A domain model relies on nothing but the core language
  """
  def model do
    quote do
    end
  end

  # todo : adapterserver (adapter implementing a behaviour, isolated via a genserver)

  @doc """
  When used, activates the appropriate macro.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

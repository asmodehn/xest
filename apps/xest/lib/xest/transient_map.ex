defmodule Xest.TransientMap do
  @moduledoc """
    A map that forgets its content after some time...
  """

  # TODO : replace this with nebulex ? or the other way around ??
  #        OR another, simpler, more standard package ?

  require Timex
  require Xest.DateTime

  @type key() :: any()
  @type value() :: any()

  defstruct birthdate: nil,
            lifetime: nil,
            store: %{}

  @type t :: %__MODULE__{
          birthdate: DateTime.t(),
          lifetime: Time.t(),
          store: map()
        }

  def new(lifetime \\ ~T[00:05:00], birthdate \\ Xest.DateTime.utc_now()) do
    # TODO : prevent negative lifetime ??
    %__MODULE__{
      lifetime: lifetime,
      birthdate: birthdate
    }
  end

  # TODO: Map API... # Note: Dict behaviour is deprecated...

  @spec delete(map(), key()) :: map()
  def delete(t, key) do
    dead_or_alive(t)
    |> Map.update!(:store, fn store -> Map.delete(store, key) end)
  end

  @spec fetch(map(), key()) :: {:ok, value()} | :error
  def fetch(t, key) do
    dead_or_alive(t) |> Map.fetch!(:store) |> Map.fetch(key)
  end

  @spec put(map(), key(), value()) :: map()
  def put(t, key, value) do
    dead_or_alive(t)
    |> Map.update!(:store, fn store -> Map.put(store, key, value) end)
  end

  defp dead_or_alive(t) do
    now = datetime().utc_now()

    case Timex.compare(
           Timex.add(t.birthdate, Timex.Duration.from_time(t.lifetime)),
           now
         ) do
      # greater cf. https://hexdocs.pm/timex/Timex.html#compare/3
      1 -> t
      # else build a new one with same lifetime...
      _ -> new(t.lifetime, now)
    end
  end

  # TODO : make this a module-level setting.
  # careful : all tests must specify the expected mock calls
  # But this is usually behind the Clock module, so it shouldnt spill too far out...
  defp datetime() do
    Application.get_env(:xest, :datetime_module, Xest.DateTime)
  end
end

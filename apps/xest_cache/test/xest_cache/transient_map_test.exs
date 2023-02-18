defmodule Xest.TransientMap.Test do
  # since we depend here on a global mock being setup...
  use ExUnit.Case, async: false

  alias XestClock.DateTime
  alias XestCache.TransientMap

  # cf https://medium.com/genesisblock/elixir-concurrent-testing-architecture-13c5e37374dc
  import Hammox

  @birthdate ~U[1970-01-02 12:34:56Z]
  @lifetime ~T[00:05:00]
  @valid_clock_time ~U[1970-01-02 12:37:56Z]
  @invalid_clock_time ~U[1970-01-02 12:44:56Z]
  @child_valid_clock_time ~U[1970-01-02 12:47:56Z]

  setup do
    # saving XestClock.DateTime implementation
    previous_datetime = Application.get_env(:xest_clock, :datetime_module)
    # Setup XestClock.DateTime Mock for these tests
    Application.put_env(:xest_clock, :datetime_module, XestClock.DateTime.Mock)

    on_exit(fn ->
      # restoring config
      Application.put_env(:xest_clock, :datetime_module, previous_datetime)
    end)
  end

  describe "Given an empty transient map (with a clock)" do
    setup :empty_transient_map

    test "When next clock time is valid, Then we can store a key/value and retrieve the value with the key",
         %{tmap: tmap} do
      DateTime.Mock
      |> expect(:utc_now, 2, fn -> @valid_clock_time end)

      tmap = TransientMap.put(tmap, :new_key, "new_value")
      assert TransientMap.fetch(tmap, :new_key) == {:ok, "new_value"}
    end

    test "When next clock time is invalid on put, Then we can still store a key/value and retrieve the value with the key",
         %{tmap: tmap} do
      DateTime.Mock
      |> expect(:utc_now, fn -> @invalid_clock_time end)
      |> expect(:utc_now, fn -> @child_valid_clock_time end)

      tmap = TransientMap.put(tmap, :new_key, "new_value")
      assert TransientMap.fetch(tmap, :new_key) == {:ok, "new_value"}
    end
  end

  describe "Given a transient map with one key value (and a clock)" do
    setup :filled_transient_map

    test "When next clock time is valid, Then we can retrieve existing value with the key",
         %{tmap: tmap} do
      DateTime.Mock
      |> expect(:utc_now, fn -> @valid_clock_time end)

      assert TransientMap.fetch(tmap, :existing) == {:ok, "value"}
    end

    test "When next clock time is invalid, Then we cannot retrieve the value",
         %{tmap: tmap} do
      DateTime.Mock
      |> expect(:utc_now, fn -> @invalid_clock_time end)

      assert TransientMap.fetch(tmap, :existing) == :error
      # Note map is immutable, so key is still there in store...
    end

    test "When next clock time is valid, Then we can store a key/value and retrieve the value with the key",
         %{tmap: tmap} do
      DateTime.Mock
      |> expect(:utc_now, 4, fn -> @valid_clock_time end)

      tmap = TransientMap.put(tmap, :new_key, "new_value")
      assert TransientMap.fetch(tmap, :new_key) == {:ok, "new_value"}
      # Note the existing key is still there and accessible
      assert tmap.store == %{new_key: "new_value", existing: "value"}
      assert TransientMap.fetch(tmap, :existing) == {:ok, "value"}
    end

    test "When next clock time is invalid on put, Then we can still store a key/value and retrieve hte value with the key",
         %{tmap: tmap} do
      DateTime.Mock
      |> expect(:utc_now, fn -> @invalid_clock_time end)
      |> expect(:utc_now, fn -> @child_valid_clock_time end)

      tmap = TransientMap.put(tmap, :new_key, "new_value")
      # Note the existing (now invalid) key is gone when we overwrote tmap
      assert tmap.store == %{new_key: "new_value"}
      assert TransientMap.fetch(tmap, :new_key) == {:ok, "new_value"}
    end
  end

  defp empty_transient_map(_) do
    DateTime.Mock
    |> expect(:utc_now, fn -> @birthdate end)

    tmap = TransientMap.new(@lifetime)
    %{tmap: tmap}
  end

  defp filled_transient_map(test) do
    # TODO : fixture with simpler in/out types...
    %{tmap: tmap} = empty_transient_map(test)

    # adding a key value pair in valid time

    DateTime.Mock
    |> expect(:utc_now, fn -> @valid_clock_time end)

    tmap = TransientMap.put(tmap, :existing, "value")
    %{tmap: tmap}
  end
end

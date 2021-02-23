defmodule Xest.DateTimeBehaviour do
  @callback utc_now() :: DateTime.t()
end

defmodule Xest.DateTime do
  @moduledoc "a simple module to be able to mock calls to DateTime"
  @behaviour Xest.DateTimeBehaviour

  @impl true
  def utc_now do
    DateTime.utc_now()
  end
end

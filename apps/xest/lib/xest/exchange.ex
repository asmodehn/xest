defmodule Xest.Exchange do
  defmodule Behaviour do
    @moduledoc "Behaviour to allow mocking a xest exchange for tests"
    @callback status(atom()) :: %Xest.Exchange.Status{}
    @callback servertime(atom()) :: %Xest.Exchange.ServerTime{}
  end

  def status(connector) do
    Xest.Exchange.Adapter.retrieve(connector, :status)
  end

  def servertime(connector) do
    Xest.Exchange.Adapter.retrieve(connector, :servertime)
  end

  def symbols(connector, opts \\ []) do
    Xest.Exchange.Adapter.retrieve(connector, :symbols)
    |> Enum.filter(fn
      # options to filter the list of symbols
      s ->
        case opts do
          # TODO : :base and :quote instead ??
          [buy: b] -> String.ends_with?(s, b)
          [sell: b] -> String.starts_with?(s, b)
          [] -> true
        end
    end)
  end
end

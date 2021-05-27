defmodule XestBinance.MonadicExchange do
  @moduledoc """
    The public part of the client (anonymous info)
    Implemented as a monad, instead of an agent.
  """

  alias XestBinance.ACL

  #  @behaviour XestBinance.Ports.ExchangeBehaviour

  # TODO : move that to the binance client genserver...
  #  @default_minimum_request_period ~T[00:00:01]

  # these are the minimal amount of state necessary
  # to estimate current real world binance exchange status
  # :minimal_request_period, :shadow_clock]
  @enforce_keys [:pubsrv]
  defstruct system_status: nil,
            servertime: nil,
            # pointing to the binance server pid
            # ,
            pubsrv: nil

  # TODO : maybe in model instead ?
  #            shadow_clock: nil  #,
  #            minimal_request_period: @default_minimum_request_period

  use Witchcraft

  import Algae.Reader

  def new(pubsrv \\ binance_server(), pubsrv_pid \\ binance_server()) do
    system_status_retrieve = fn _utc_now ->
      # TODO : use utc_now to figure out if retrieving is needed or not.
      # TODO : leverage elixir's 'with' ?
      {:ok, exg_raw} = pubsrv.system_status(pubsrv_pid)
      {ACL.to_xest(exg_raw), exg_raw}
    end

    %__MODULE__{
      system_status: system_status_retrieve |> ask(),
      servertime: Xest.ShadowClock.new(fn -> pubsrv.time!(pubsrv_pid) end),
      pubsrv: pubsrv
    }
  end

  def system_status(%__MODULE__{system_status: reader}, utc_now \\ &DateTime.utc_now/0) do
    reader |> run(utc_now.()) |> elem(0)
  end

  def servertime(%__MODULE__{servertime: shadowclock}, _utc_now \\ &DateTime.utc_now/0) do
    Xest.ShadowClock.update(shadowclock)
  end

  defp binance_server do
    Application.get_env(:xest, :binance_server)
  end
end

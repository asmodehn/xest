defmodule XestKraken.Exchange.Behaviour do
  @moduledoc """
  TODO... move this to Xest to make it general
          || lowest common denominator for all connectors
  """

  @type status :: XestKraken.Exchange.Status.t()
  @type reason :: String.t()

  #  @type servertime :: Xest.ShadowClock.t()
  @type mockable_pid :: nil | pid()

  # | {:error, reason}
  @callback status(mockable_pid()) :: status

  # | {:error, reason}
  #  @callback servertime(mockable_pid()) :: servertime

  # TODO : by leveraging __using__ we could implement default function
  #                                   and their unsafe counterparts maybe ?
end

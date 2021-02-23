defmodule Xest.LocalUTCClock do
  @callback utc_now() :: DateTime.t()
end